import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/Components/CommonComponents/MapLocationPicker.dart';
import 'package:restaurantdashboard/Providers/ResturantProvider.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:restaurantdashboard/features/profile/presentation/cubit/profile_state.dart';
import 'package:restaurantdashboard/features/profile/presentation/widgets/profile_image_section.dart';
import 'package:restaurantdashboard/features/profile/presentation/widgets/profile_stats_card.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/cubit/navigation_cubit.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_action.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_slot_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _orderTimeController = TextEditingController();
  final Object _headerOwner = Object();
  PageHeaderSlotController? _headerSlot;

  String? _boundRestaurantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _headerSlot = context.read<PageHeaderSlotController>();
  }

  @override
  void dispose() {
    _headerSlot?.clear(_headerOwner);
    _ownerNameController.dispose();
    _restaurantNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _orderTimeController.dispose();
    super.dispose();
  }

  void _syncFormFromRestaurant(Restaurant restaurant, {bool force = false}) {
    if (!force && _boundRestaurantId == restaurant.id) return;
    _boundRestaurantId = restaurant.id;
    _ownerNameController.text = restaurant.ownerName;
    _restaurantNameController.text = restaurant.resturantName;
    _emailController.text = restaurant.email;
    _addressController.text = restaurant.address;
    _orderTimeController.text = restaurant.orderTimeFinish;
  }

  void _syncHeaderActions({
    required bool isActive,
    required ProfileCubit cubit,
    required ProfileState state,
    required Restaurant restaurant,
  }) {
    if (!mounted) return;
    final slot = _headerSlot;
    if (slot == null) return;
    if (!isActive) {
      slot.clear(_headerOwner);
      return;
    }

    if (state.isEditing) {
      slot.setActions(_headerOwner, [
        PageHeaderAction(
          icon: Icons.close_rounded,
          label: 'إلغاء',
          tooltip: 'إلغاء',
          onPressed: state.isSaving ? null : cubit.cancelEditing,
        ),
        PageHeaderAction(
          icon: Icons.save_rounded,
          label: 'حفظ',
          tooltip: 'حفظ التغييرات',
          onPressed: state.isSaving ? null : () => _save(cubit),
        ),
      ]);
      return;
    }

    slot.setActions(_headerOwner, [
      PageHeaderAction(
        icon: Icons.edit_rounded,
        label: 'تعديل',
        tooltip: 'تعديل الملف',
        onPressed: () => cubit.startEditing(restaurant),
      ),
    ]);
  }

  Future<void> _pickImage(ProfileCubit cubit) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('تعذر قراءة ملف الصورة');
      }

      cubit.selectImage(bytes, file.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في اختيار الصورة: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickLocation(
    ProfileCubit cubit,
    Restaurant restaurant,
  ) async {
    final result = await showMapLocationPickerDialog(
      context,
      initialLocation: LatLng(restaurant.latitude, restaurant.longitude),
    );
    if (result == null || !mounted) return;

    final LatLng selectedLatLng = result['latlng'];
    final String selectedAddress = result['address'];
    cubit.setLocation(
      latitude: selectedLatLng.latitude,
      longitude: selectedLatLng.longitude,
    );
    _addressController.text = selectedAddress;
    setState(() {});
  }

  Future<void> _save(ProfileCubit cubit) async {
    if (!_formKey.currentState!.validate()) return;

    await cubit.save(
      authProvider: context.read<AuthProvider>(),
      restaurantProvider: context.read<RestaurantProvider>(),
      ownerName: _ownerNameController.text.trim(),
      restaurantName: _restaurantNameController.text.trim(),
      address: _addressController.text.trim(),
      orderTimeFinish: _orderTimeController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = context.select(
      (NavigationCubit c) => c.state.currentItem == NavigationItem.profile,
    );

    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen:
          (previous, current) =>
              previous.lastError != current.lastError ||
              previous.successMessage != current.successMessage,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.successMessage != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
          context.read<ProfileCubit>().clearMessages();
        } else if (state.lastError != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.lastError!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<ProfileCubit>().clearMessages();
        }
      },
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final restaurant = authProvider.restaurant;
          if (restaurant == null) {
            return const Center(child: Text('لا توجد بيانات للمطعم'));
          }

          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (!state.isEditing) {
                _syncFormFromRestaurant(restaurant, force: true);
              } else if (_boundRestaurantId != restaurant.id) {
                _syncFormFromRestaurant(restaurant);
              }

              final cubit = context.read<ProfileCubit>();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _syncHeaderActions(
                  isActive: isActive,
                  cubit: cubit,
                  state: state,
                  restaurant: restaurant,
                );
              });

              final theme = Theme.of(context);
              final scheme = theme.colorScheme;

              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfileStatsCard(restaurant: restaurant),
                          const SizedBox(height: 12),
                          Material(
                            color: scheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: scheme.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: ProfileImageSection(
                                restaurant: restaurant,
                                isEditing: state.isEditing,
                                selectedImageBytes: state.selectedImageBytes,
                                onPickImage: () => _pickImage(cubit),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            restaurant: restaurant,
                            isEditing: state.isEditing,
                            ownerNameController: _ownerNameController,
                            restaurantNameController:
                                _restaurantNameController,
                            emailController: _emailController,
                            addressController: _addressController,
                            orderTimeController: _orderTimeController,
                            onPickLocation:
                                () => _pickLocation(cubit, restaurant),
                          ),
                          if (state.isEditing) ...[
                            const SizedBox(height: 16),
                            _ActionButtons(
                              isSaving: state.isSaving,
                              onCancel: cubit.cancelEditing,
                              onSave: () => _save(cubit),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.restaurant,
    required this.isEditing,
    required this.ownerNameController,
    required this.restaurantNameController,
    required this.emailController,
    required this.addressController,
    required this.orderTimeController,
    required this.onPickLocation,
  });

  final Restaurant restaurant;
  final bool isEditing;
  final TextEditingController ownerNameController;
  final TextEditingController restaurantNameController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController orderTimeController;
  final VoidCallback onPickLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'معلومات المطعم',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _ProfileTextField(
              controller: ownerNameController,
              label: 'اسم المالك',
              icon: Icons.person_outline_rounded,
              enabled: isEditing,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: restaurantNameController,
              label: 'اسم المطعم',
              icon: Icons.storefront_outlined,
              enabled: isEditing,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: emailController,
              label: 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              enabled: false,
            ),
            const SizedBox(height: 12),
            _LocationField(
              address: addressController.text,
              isEditing: isEditing,
              onTap: onPickLocation,
            ),
            const SizedBox(height: 12),
            _ProfileTextField(
              controller: orderTimeController,
              label: 'وقت تحضير الطلب',
              icon: Icons.timer_outlined,
              enabled: isEditing,
            ),
            const SizedBox(height: 14),
            _AccountStatusChip(accountStatus: restaurant.accountStatus),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.address,
    required this.isEditing,
    required this.onTap,
  });

  final String address;
  final bool isEditing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: isEditing ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: isEditing ? AppColors.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العنوان',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      address.isNotEmpty ? address : 'لا يوجد عنوان محدد',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            address.isNotEmpty
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEditing)
                const Icon(
                  Icons.edit_location_alt_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        isDense: true,
      ),
      validator: (value) {
        if (enabled && (value == null || value.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }
}

class _AccountStatusChip extends StatelessWidget {
  const _AccountStatusChip({required this.accountStatus});

  final String accountStatus;

  @override
  Widget build(BuildContext context) {
    final isActive = accountStatus.toLowerCase() == 'active';
    final color = isActive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(color, 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.withOpacity(color, 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'حساب نشط' : 'حساب معطل',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child:
                isSaving
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                    : const Text(
                      'حفظ التغييرات',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
          ),
        ),
      ],
    );
  }
}

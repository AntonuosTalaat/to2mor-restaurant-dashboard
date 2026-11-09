import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/Components/CommonComponents/AppNetworkImage.dart';
import 'package:restaurantdashboard/Components/CommonComponents/MapLocationPicker.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/LoginScreen.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_brand_mark.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:restaurantdashboard/shared/widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  bool _acceptTerms = false;
  Uint8List? _restaurantLogo;
  String? _imageUrl;
  String? _imageFileName;
  String? _selectedType;

  final LatLng _sourceLocation = const LatLng(30.0444, 31.2357);
  LatLng? _selectedLocation;

  final List<Map<String, String>> _restaurantTypes = const [
    {'value': 'food', 'label': 'مطعم'},
    {'value': 'supermarket', 'label': 'سوبر ماركت'},
    {'value': 'pharmacy', 'label': 'صيدلية'},
    {'value': 'mart', 'label': 'مارت'},
  ];

  @override
  void dispose() {
    _ownerNameController.dispose();
    _restaurantNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    final result = await showMapLocationPickerDialog(
      context,
      initialLocation: _sourceLocation,
    );

    if (result != null && result['latlng'] != null) {
      setState(() {
        _selectedLocation = result['latlng'] as LatLng;
        _addressController.text = result['address'] ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
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

      setState(() {
        _restaurantLogo = bytes;
        _imageUrl = null;
        _imageFileName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleSignUp(AuthProvider authProvider) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى الموافقة على الشروط والأحكام'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_restaurantLogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار شعار للمطعم'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد موقع المطعم على الخريطة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await authProvider.registerRestaurant(
        ownerName: _ownerNameController.text.trim(),
        restaurantName: _restaurantNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        address: _addressController.text.trim(),
        imageBytes: _restaurantLogo!,
        imageFileName: _imageFileName ?? 'restaurant_logo.jpg',
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        restaurantType: _selectedType ?? '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل المطعم بنجاح!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthScaffold(
      showBackButton: true,
      maxContentWidth: 560,
      child: Column(
        children: [
          const AuthBrandMark(
            compact: true,
            size: 64,
            subtitle: 'إنشاء حساب مطعم جديد',
          ),
          const SizedBox(height: 24),
          AuthFormCard(
            child: Form(
              key: _formKey,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _buildLogoPicker(scheme)),
                    const SizedBox(height: 8),
                    Text(
                      'شعار المطعم',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (_restaurantLogo != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.withOpacity(AppColors.success, 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.withOpacity(
                              AppColors.success,
                              0.3,
                            ),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'تم اختيار الصورة',
                              style: TextStyle(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'بيانات النشاط'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _restaurantNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المطعم',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'يرجى إدخال اسم المطعم'
                                  : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      readOnly: true,
                      onTap: _selectLocation,
                      decoration: InputDecoration(
                        labelText: 'عنوان المطعم',
                        hintText:
                            _selectedLocation == null
                                ? 'انقر لتحديد الموقع على الخريطة'
                                : 'تم تحديد الموقع',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color:
                              _selectedLocation != null
                                  ? AppColors.success
                                  : null,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال عنوان المطعم';
                        }
                        if (_selectedLocation == null) {
                          return 'يرجى تحديد موقع المطعم على الخريطة';
                        }
                        return null;
                      },
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'الإحداثيات: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'نوع النشاط',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      hint: const Text('اختر نوع النشاط'),
                      items:
                          _restaurantTypes
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type['value'],
                                  child: Text(type['label']!),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => _selectedType = value),
                      validator:
                          (value) =>
                              value == null ? 'يرجى اختيار نوع النشاط' : null,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'بيانات الحساب'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المالك',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'يرجى إدخال اسمك الكامل'
                                  : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال بريدك الإلكتروني';
                        }
                        if (!value.contains('@')) {
                          return 'البريد الإلكتروني غير صالح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator:
                          (value) =>
                              value != _passwordController.text
                                  ? 'كلمة المرور غير متطابقة'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged:
                              (value) => setState(
                                () => _acceptTerms = value ?? false,
                              ),
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: Text(
                            'أوافق على الشروط والأحكام وسياسة الخصوصية',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      labelAr: 'تسجيل المطعم',
                      isLoading: authProvider.isLoading,
                      onPressed:
                          authProvider.isLoading
                              ? null
                              : () => _handleSignUp(authProvider),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لديك حساب بالفعل؟',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPicker(ColorScheme scheme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    _restaurantLogo != null
                        ? AppColors.success
                        : AppColors.primary,
                width: 3,
              ),
            ),
            child: ClipOval(
              child:
                  _restaurantLogo == null
                      ? const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 42,
                        color: AppColors.primaryDark,
                      )
                      : (_imageUrl != null
                          ? AppNetworkImage(
                            imageUrl: _imageUrl!,
                            fit: BoxFit.cover,
                          )
                          : Image.memory(_restaurantLogo!, fit: BoxFit.cover)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _restaurantLogo != null
                        ? AppColors.success
                        : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _restaurantLogo != null ? Icons.check : Icons.add_a_photo,
                color: AppColors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

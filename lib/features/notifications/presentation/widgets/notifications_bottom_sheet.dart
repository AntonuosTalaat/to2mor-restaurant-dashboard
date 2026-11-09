import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:restaurantdashboard/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

class NotificationsBottomSheet extends StatefulWidget {
  const NotificationsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider.value(
          value: context.read<NotificationCubit>(),
          child: const NotificationsBottomSheet(),
        ),
      ),
    );
  }

  @override
  State<NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<String> ids) {
    setState(() {
      if (_selectedIds.length == ids.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  Future<void> _confirmDelete({
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await onConfirm();
      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    await _confirmDelete(
      title: 'حذف الإشعارات',
      message: 'هل تريد حذف $count ${count == 1 ? 'إشعار' : 'إشعارات'}؟',
      onConfirm: () => context
          .read<NotificationCubit>()
          .deleteNotifications(_selectedIds.toList(growable: false)),
    );
  }

  Future<void> _deleteAll() async {
    await _confirmDelete(
      title: 'حذف كل الإشعارات',
      message: 'هل تريد حذف جميع الإشعارات؟ لا يمكن التراجع عن هذا الإجراء.',
      onConfirm: () => context.read<NotificationCubit>().deleteAllNotifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.withOpacity(
                  AppColors.black,
                  isDark ? 0.4 : 0.12,
                ),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  final allIds =
                      state.notifications.map((n) => n.id).toList(growable: false);
                  return _NotificationsHeader(
                    isDark: isDark,
                    selectionMode: _selectionMode,
                    selectedCount: _selectedIds.length,
                    totalCount: state.notifications.length,
                    allSelected: allIds.isNotEmpty &&
                        _selectedIds.length == allIds.length,
                    onToggleSelectionMode: _toggleSelectionMode,
                    onSelectAll: () => _selectAll(allIds),
                    onDeleteSelected: _deleteSelected,
                    onDeleteAll: _deleteAll,
                  );
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, state) {
                    if (state.isLoading && state.notifications.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      );
                    }

                    if (state.notifications.isEmpty) {
                      return _EmptyNotifications(isDark: isDark);
                    }

                    final cubit = context.read<NotificationCubit>();

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      itemCount: state.notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        final isSelected =
                            _selectedIds.contains(notification.id);

                        return NotificationTile(
                          notification: notification,
                          selectionMode: _selectionMode,
                          isSelected: isSelected,
                          onSelectionToggle: () =>
                              _toggleSelection(notification.id),
                          onTap: () {
                            if (_selectionMode) {
                              _toggleSelection(notification.id);
                              return;
                            }
                            Navigator.of(context).pop();
                            cubit.handleNotificationTap(notification);
                          },
                          onDismiss: () =>
                              cubit.deleteNotification(notification.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.isDark,
    required this.selectionMode,
    required this.selectedCount,
    required this.totalCount,
    required this.allSelected,
    required this.onToggleSelectionMode,
    required this.onSelectAll,
    required this.onDeleteSelected,
    required this.onDeleteAll,
  });

  final bool isDark;
  final bool selectionMode;
  final int selectedCount;
  final int totalCount;
  final bool allSelected;
  final VoidCallback onToggleSelectionMode;
  final VoidCallback onSelectAll;
  final VoidCallback onDeleteSelected;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [
                            AppColors.goldDark20,
                            AppColors.goldDark10,
                          ],
                        )
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selectionMode
                      ? Icons.checklist_rounded
                      : Icons.notifications_active_rounded,
                  color: isDark ? AppColors.primaryLight : AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectionMode ? 'تحديد الإشعارات' : 'الإشعارات',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    BlocBuilder<NotificationCubit, NotificationState>(
                      builder: (context, state) {
                        if (selectionMode) {
                          return Text(
                            selectedCount > 0
                                ? 'تم تحديد $selectedCount من $totalCount'
                                : 'اختر إشعاراً واحداً أو أكثر للحذف',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                            ),
                          );
                        }
                        final unread = state.unreadCount;
                        return Text(
                          unread > 0
                              ? 'لديك $unread ${unread == 1 ? 'إشعار جديد' : 'إشعارات جديدة'}'
                              : 'لا توجد إشعارات جديدة',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (!selectionMode && totalCount > 0)
                IconButton(
                  tooltip: 'تحديد للحذف',
                  onPressed: onToggleSelectionMode,
                  icon: const Icon(Icons.checklist_rounded),
                ),
              if (selectionMode)
                TextButton(
                  onPressed: onToggleSelectionMode,
                  child: const Text('إلغاء'),
                ),
            ],
          ),
          if (totalCount > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.start,
              children: [
                if (selectionMode) ...[
                  TextButton.icon(
                    onPressed: onSelectAll,
                    icon: Icon(
                      allSelected
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      size: 18,
                    ),
                    label: Text(allSelected ? 'إلغاء التحديد' : 'تحديد الكل'),
                  ),
                  TextButton.icon(
                    onPressed: selectedCount > 0 ? onDeleteSelected : null,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(
                      selectedCount > 0
                          ? 'حذف المحدد ($selectedCount)'
                          : 'حذف المحدد',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDeleteAll,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('حذف الكل'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ] else ...[
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, state) {
                      if (state.unreadCount == 0) {
                        return const SizedBox.shrink();
                      }
                      return TextButton.icon(
                        onPressed: () =>
                            context.read<NotificationCubit>().markAllAsRead(),
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('قراءة الكل'),
                      );
                    },
                  ),
                  TextButton.icon(
                    onPressed: onDeleteAll,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('حذف الكل'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: AppColors.withOpacity(textSecondary, 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد إشعارات',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر هنا إشعارات الطلبات الجديدة والطلبات الملغاة',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatNotificationTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';

  return DateFormat('d MMM yyyy - HH:mm', 'ar').format(dateTime);
}

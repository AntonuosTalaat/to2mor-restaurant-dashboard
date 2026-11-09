import 'package:restaurantdashboard/core/utils/web_app_reload.dart';
import 'package:restaurantdashboard/shared/widgets/header_icon_chip.dart';
import 'package:restaurantdashboard/shared/widgets/notification_bell.dart';
import 'package:restaurantdashboard/shared/widgets/theme_toggle_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PageHeaderActions extends StatefulWidget {
  const PageHeaderActions({
    super.key,
    required this.onRefresh,
    this.notificationCount = 0,
    this.onNotificationsTap,
    this.leadingActions = const [],
    this.showVersionUpdate = false,
    this.chipSize = 34,
    this.iconSize = 19,
  });

  final Future<void> Function() onRefresh;
  final int notificationCount;
  final VoidCallback? onNotificationsTap;

  /// Page-specific actions (e.g. Add / Excel) shown before refresh/notifications.
  final List<Widget> leadingActions;

  /// App version reload — typically only on the dashboard.
  final bool showVersionUpdate;

  final double chipSize;
  final double iconSize;

  @override
  State<PageHeaderActions> createState() => _PageHeaderActionsState();
}

class _PageHeaderActionsState extends State<PageHeaderActions>
    with SingleTickerProviderStateMixin {
  bool _refreshing = false;
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _spinController.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinController.stop();
        _spinController.reset();
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final action in widget.leadingActions) ...[
          action,
          const SizedBox(width: 6),
        ],
        NotificationBell(
          count: widget.notificationCount,
          onPressed: widget.onNotificationsTap,
          size: widget.chipSize,
          iconSize: widget.iconSize,
        ),
        if (!isAndroid) ...[
          const SizedBox(width: 6),
          RotationTransition(
            turns: _spinController,
            child: HeaderIconChip(
              icon: Icons.refresh_rounded,
              onPressed: _refreshing ? null : _handleRefresh,
              tooltip: 'تحديث البيانات',
              size: widget.chipSize,
              iconSize: widget.iconSize,
              isActive: _refreshing,
            ),
          ),
          if (widget.showVersionUpdate) ...[
            const SizedBox(width: 6),
            HeaderIconChip(
              icon: Icons.system_update_alt_rounded,
              onPressed: () => reloadWebAppToLatest(),
              tooltip: 'تحديث النسخة',
              size: widget.chipSize,
              iconSize: widget.iconSize,
            ),
          ],
        ],
        const SizedBox(width: 8),
        const ThemeToggleButton(),
      ],
    );
  }
}

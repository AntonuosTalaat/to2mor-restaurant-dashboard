import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/Providers/ResturantProvider.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';

class TabFilter extends StatefulWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const TabFilter({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  State<TabFilter> createState() => _TabFilterState();
}

class _TabFilterState extends State<TabFilter> {
  static const _tabs = ['اليوم', 'الأسبوع', 'الشهر'];
  static const _timeOptions = ['15m', '20m', '30m', '45m', '1h', '1h 30m'];
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fetched =
          context.read<RestaurantProvider>().restaurant?.orderTimeFinish;
      if (!mounted) return;
      setState(() => _selectedTime = fetched ?? '20m');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final restaurantProvider = context.watch<RestaurantProvider>();
    final selectedTime =
        _timeOptions.contains(_selectedTime) ? _selectedTime! : '20m';

    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OpenStatusBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 620;
                final onTimeChanged = (String value) async {
                  setState(() => _selectedTime = value);
                  await restaurantProvider.updateOrderTimeFinish(value);
                };

                if (isMobile) {
                  return Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown(
                          label: 'فترة التحليل',
                          icon: Icons.calendar_month_outlined,
                          value: widget.selectedPeriod,
                          options: _tabs,
                          onChanged: widget.onPeriodChanged,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterDropdown(
                          label: 'وقت التحضير',
                          icon: Icons.timer_outlined,
                          value: selectedTime,
                          options: _timeOptions,
                          onChanged: onTimeChanged,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _PeriodSegmentedControl(
                        selectedPeriod: widget.selectedPeriod,
                        onPeriodChanged: widget.onPeriodChanged,
                        tabs: _tabs,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _FilterDropdown(
                        label: 'وقت التحضير',
                        icon: Icons.timer_outlined,
                        value: selectedTime,
                        options: _timeOptions,
                        onChanged: onTimeChanged,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenStatusBanner extends StatelessWidget {
  const _OpenStatusBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AuthProvider>(
      builder: (context, provider, _) {
        final isOpen = (provider.restaurant?.openStatus ?? 'closed') == 'open';
        final color = isOpen ? AppColors.success : AppColors.error;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.withOpacity(color, 0.12),
            border: Border(
              bottom: BorderSide(
                color: AppColors.withOpacity(color, 0.22),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.withOpacity(color, 0.55),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen ? 'المطعم مفتوح' : 'المطعم مغلق',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      isOpen
                          ? 'يستقبل الطلبات حالياً'
                          : 'لن تظهر الطلبات الجديدة للعملاء',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isOpen,
                activeTrackColor: AppColors.success,
                onChanged: (value) async {
                  await provider.updateOpenStatus(value ? 'open' : 'closed');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'تم فتح المطعم' : 'تم غلق المطعم',
                      ),
                      backgroundColor:
                          value ? AppColors.success : AppColors.error,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: scheme.onSurfaceVariant,
              ),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              dropdownColor: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              items:
                  options
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
              onChanged: (selected) {
                if (selected == null) return;
                onChanged(selected);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodSegmentedControl extends StatelessWidget {
  const _PeriodSegmentedControl({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.tabs,
  });

  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'فترة التحليل',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _PeriodSegment(
                    label: tabs[i],
                    selected: selectedPeriod == tabs[i],
                    onTap: () => onPeriodChanged(tabs[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        boxShadow:
            selected
                ? [
                  BoxShadow(
                    color: AppColors.withOpacity(AppColors.primary, 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Color(0xFF1A140C),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color:
                        selected
                            ? const Color(0xFF1A140C)
                            : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

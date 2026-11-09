import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/Components/CommonComponents/StateComponents.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/reviews/data/models/RestaurantReviewModel.dart';
import 'package:restaurantdashboard/features/reviews/presentation/cubit/reviews_cubit.dart';
import 'package:restaurantdashboard/features/reviews/presentation/cubit/reviews_state.dart';
import 'package:restaurantdashboard/features/reviews/presentation/widgets/review_card.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/cubit/navigation_cubit.dart';
import 'package:restaurantdashboard/shared/shared_data_table/shared_data_table.dart';
import 'package:restaurantdashboard/shared/shared_data_table/shared_data_table_config.dart';
import 'package:restaurantdashboard/shared/widgets/compact_stats_banner.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_slot_controller.dart';
import 'package:restaurantdashboard/shared/widgets/responsive_filter_row.dart';

class RestaurantReviewsScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantReviewsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantReviewsScreen> createState() =>
      _RestaurantReviewsScreenState();
}

class _RestaurantReviewsScreenState extends State<RestaurantReviewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Object _headerOwner = Object();
  PageHeaderSlotController? _headerSlot;

  static const _ratingFilters = <String>[
    'الكل',
    '5 نجوم',
    '4 نجوم',
    '3 نجوم',
    '2 نجوم',
    '1 نجمة',
  ];

  static const _periodFilters = <String>[
    'كل الفترات',
    'آخر 7 أيام',
    'آخر 30 يوم',
    'آخر 90 يوم',
  ];

  static const _columns = <DataTableColumn>[
    DataTableColumn(label: 'العميل', icon: Icons.person_outline_rounded),
    DataTableColumn(label: 'الطلب', icon: Icons.receipt_long_outlined),
    DataTableColumn(label: 'التقييم', icon: Icons.star_outline_rounded),
    DataTableColumn(label: 'التعليق', icon: Icons.chat_bubble_outline_rounded),
    DataTableColumn(label: 'التاريخ', icon: Icons.schedule_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      final cubit = context.read<ReviewsCubit>();
      if (next.toLowerCase() == cubit.state.searchQuery) return;
      cubit.setSearchQuery(next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewsCubit>().loadRestaurantData(widget.restaurantId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _headerSlot = context.read<PageHeaderSlotController>();
  }

  @override
  void dispose() {
    _headerSlot?.clear(_headerOwner);
    _searchController.dispose();
    super.dispose();
  }

  void _syncHeaderActions({
    required bool isActive,
    required ReviewsState state,
  }) {
    if (!mounted) return;
    final slot = _headerSlot;
    if (slot == null) return;
    if (!isActive) {
      slot.clear(_headerOwner);
      return;
    }

    slot.setActions(_headerOwner, [
      _PeriodHeaderChip(
        value: _periodFilterLabel(state),
        options: _periodFilters,
        onChanged: _onPeriodFilterChanged,
      ),
    ]);
  }

  String _ratingFilterLabel(ReviewsState state) {
    final rating = state.selectedRating;
    if (rating == null) return 'الكل';
    return switch (rating.round()) {
      5 => '5 نجوم',
      4 => '4 نجوم',
      3 => '3 نجوم',
      2 => '2 نجوم',
      1 => '1 نجمة',
      _ => 'الكل',
    };
  }

  String _periodFilterLabel(ReviewsState state) {
    return switch (state.selectedDays) {
      7 => 'آخر 7 أيام',
      30 => 'آخر 30 يوم',
      90 => 'آخر 90 يوم',
      _ => 'كل الفترات',
    };
  }

  void _onRatingFilterChanged(String value) {
    final cubit = context.read<ReviewsCubit>();
    final rating = switch (value) {
      '5 نجوم' => 5.0,
      '4 نجوم' => 4.0,
      '3 نجوم' => 3.0,
      '2 نجوم' => 2.0,
      '1 نجمة' => 1.0,
      _ => null,
    };
    cubit.setRatingFilter(rating);
  }

  void _onPeriodFilterChanged(String value) {
    final days = switch (value) {
      'آخر 7 أيام' => 7,
      'آخر 30 يوم' => 30,
      'آخر 90 يوم' => 90,
      _ => 0,
    };
    context.read<ReviewsCubit>().setDaysFilter(days);
  }

  List<CompactStatItem> _buildStats(ReviewsState state, ReviewsCubit cubit) {
    final withComments =
        state.restaurantReviews
            .where(
              (r) =>
                  r.restaurantComment != null &&
                  r.restaurantComment!.trim().isNotEmpty,
            )
            .length;
    final thisMonth = cubit.getReviewCountForPeriod(30);

    return [
      CompactStatItem(
        title: 'إجمالي التقييمات',
        value: '${state.totalReviews}',
        icon: Icons.rate_review_rounded,
        color: AppColors.primary,
      ),
      CompactStatItem(
        title: 'متوسط التقييم',
        value: state.averageRating.toStringAsFixed(1),
        icon: Icons.star_rounded,
        color: AppColors.warning,
      ),
      CompactStatItem(
        title: 'هذا الشهر',
        value: '$thisMonth',
        icon: Icons.calendar_month_outlined,
        color: AppColors.info,
      ),
      CompactStatItem(
        title: 'بتعليق',
        value: '$withComments',
        icon: Icons.chat_bubble_outline_rounded,
        color: AppColors.success,
      ),
    ];
  }

  DataTableConfig _tableConfig(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return DataTableConfig(
      containerMargin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      containerColor: theme.colorScheme.surface,
      containerBorderRadius: BorderRadius.circular(12),
      containerShadow: [
        BoxShadow(
          color: AppColors.withOpacity(AppColors.black, isDark ? 0.28 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      columnSpacing: 16,
      horizontalMargin: 12,
      headingRowHeight: 52,
      dataRowHeight: 76,
      headingRowColor:
          isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      dividerThickness: 1,
      showCheckboxColumn: false,
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    bool compact = false,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: compact ? 18 : 22),
        prefixIconConstraints:
            compact
                ? const BoxConstraints(minWidth: 32, minHeight: 32)
                : null,
        isDense: true,
        contentPadding:
            compact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items:
              options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: (next) {
            if (next == null) return;
            onChanged(next);
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} د';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} س';
    if (difference.inDays < 30) return 'منذ ${difference.inDays} يوم';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  DataRow _buildRow(BuildContext context, RestaurantReview review) {
    final scheme = Theme.of(context).colorScheme;
    final comment = review.restaurantComment?.trim() ?? '';
    final rating = review.restaurantRating.clamp(0, 5);
    final initial =
        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '؟';

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.withOpacity(AppColors.primary, 0.14),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.userName.isEmpty ? 'عميل' : review.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text('#${review.shortOrderId}')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            comment.isEmpty ? '—' : comment,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  comment.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
            ),
          ),
        ),
        DataCell(Text(_formatTime(review.createdAt))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = context.select(
      (NavigationCubit c) => c.state.currentItem == NavigationItem.reviews,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocConsumer<ReviewsCubit, ReviewsState>(
          listenWhen:
              (previous, current) =>
                  previous.selectedDays != current.selectedDays,
          listener: (context, state) {
            _syncHeaderActions(isActive: isActive, state: state);
          },
          builder: (context, state) {
            final cubit = context.read<ReviewsCubit>();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _syncHeaderActions(isActive: isActive, state: state);
            });

            if (state.isLoading && state.restaurantReviews.isEmpty) {
              return const LoadingState();
            }

            final reviews = state.visibleReviews;
            final isCompact = MediaQuery.sizeOf(context).width < 768;
            final hasFilters =
                state.searchQuery.isNotEmpty ||
                state.selectedRating != null ||
                state.showOnlyWithComments ||
                state.selectedDays > 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompactStatsBanner(
                  items: _buildStats(state, cubit),
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: ResponsiveFilterRow(
                    spacing: isCompact ? 6 : 8,
                    items: [
                      ResponsiveFilterRowItem(
                        flex: isCompact ? 3 : 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'بحث',
                            hintText:
                                isCompact
                                    ? 'اسم...'
                                    : 'اسم العميل، رقم الطلب، أو التعليق',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: isCompact ? 18 : 22,
                            ),
                            prefixIconConstraints:
                                isCompact
                                    ? const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    )
                                    : null,
                            isDense: true,
                            contentPadding:
                                isCompact
                                    ? const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    )
                                    : null,
                            suffixIcon:
                                state.searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                      tooltip: 'مسح',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        _searchController.clear();
                                        cubit.setSearchQuery('');
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: isCompact ? 18 : 22,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                      ResponsiveFilterRowItem(
                        flex: isCompact ? 2 : 1,
                        child: _buildDropdownFilter(
                          label: isCompact ? 'التقييم' : 'عدد النجوم',
                          icon: Icons.star_outline_rounded,
                          value: _ratingFilterLabel(state),
                          options: _ratingFilters,
                          compact: isCompact,
                          onChanged: _onRatingFilterChanged,
                        ),
                      ),
                      ResponsiveFilterRowItem(
                        flex: isCompact ? 2 : 1,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: isCompact ? 'التعليق' : 'التعليقات',
                            prefixIcon: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: isCompact ? 18 : 22,
                            ),
                            prefixIconConstraints:
                                isCompact
                                    ? const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    )
                                    : null,
                            isDense: true,
                            contentPadding:
                                isCompact
                                    ? const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    )
                                    : null,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              value: state.showOnlyWithComments,
                              isExpanded: true,
                              isDense: true,
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 14,
                                color: theme.colorScheme.onSurface,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: false,
                                  child: Text('الكل'),
                                ),
                                DropdownMenuItem(
                                  value: true,
                                  child: Text('بتعليق فقط'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                if (value != state.showOnlyWithComments) {
                                  cubit.toggleCommentsFilter();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh:
                        () => cubit.refreshReviews(widget.restaurantId),
                    child: SharedDataTable<RestaurantReview>(
                      items: reviews,
                      columns: _columns,
                      rowBuilder: _buildRow,
                      config: _tableConfig(theme),
                      itemsPerPage: 10,
                      mobilePreferList: true,
                      mobileCardSpacing: 8,
                      mobileCardBuilder:
                          (context, review) => ReviewCard(review: review),
                      emptyWidget: EmptyState(
                        title: 'لا توجد تقييمات',
                        subtitle:
                            hasFilters
                                ? 'لا توجد نتائج مطابقة للبحث أو الفلاتر'
                                : 'ستظهر هنا تقييمات العملاء بعد إكمال الطلبات',
                        icon: Icons.rate_review_outlined,
                      ),
                      paginationLabelBuilder:
                          (from, to, total) =>
                              'عرض $from-$to من أصل $total تقييم',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PeriodHeaderChip extends StatelessWidget {
  const _PeriodHeaderChip({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  static String _shortLabel(String value) => switch (value) {
    'آخر 7 أيام' => '7 أيام',
    'آخر 30 يوم' => '30 يوم',
    'آخر 90 يوم' => '90 يوم',
    _ => 'الفترة',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Material(
      color: AppColors.withOpacity(AppColors.primary, 0.12),
      borderRadius: BorderRadius.circular(10),
      child: PopupMenuButton<String>(
        tooltip: 'فترة التقييمات',
        initialValue: value,
        onSelected: onChanged,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder:
            (context) =>
                options
                    .map(
                      (option) => PopupMenuItem<String>(
                        value: option,
                        child: Row(
                          children: [
                            Icon(
                              option == value
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 16,
                              color:
                                  option == value
                                      ? AppColors.primary
                                      : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              option,
                              style: TextStyle(
                                fontWeight:
                                    option == value
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                color:
                                    option == value
                                        ? AppColors.primary
                                        : scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 8 : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isMobile ? _shortLabel(value) : value,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 12 : null,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

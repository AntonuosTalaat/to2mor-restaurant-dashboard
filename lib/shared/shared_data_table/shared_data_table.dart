import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/shared/shared_data_table/shared_data_table_config.dart';
import 'package:flutter/material.dart';

/// Shared DataTable Component with consistent styling
class SharedDataTable<T> extends StatefulWidget {
  /// List of items to display
  final List<T> items;

  /// Column definitions
  final List<DataTableColumn> columns;

  /// Function to build each row
  final DataRow Function(BuildContext context, T item) rowBuilder;

  /// Function to build mobile card view (optional)
  final Widget Function(BuildContext context, T item)? mobileCardBuilder;

  /// Items per page (default: 8)
  final int itemsPerPage;

  /// Empty state widget
  final Widget? emptyWidget;

  /// Custom configuration
  final DataTableConfig? config;

  /// Show pagination
  final bool showPagination;

  /// Enable horizontal scroll
  final bool enableHorizontalScroll;

  /// Table width (optional, default: screen width - 200)
  final double? tableWidth;

  /// Custom pagination text, e.g. (from, to, total) => 'عرض $from-$to من أصل $total لوح'
  final String Function(int from, int to, int total)? paginationLabelBuilder;
  final double? width;
  final Widget? header;

  /// Fixed card size for mobile grid (when [mobileCardBuilder] is set).
  final double mobileCardWidth;
  final double mobileCardHeight;
  final double mobileCardSpacing;

  /// On narrow phones, prefer a full-width list over a fixed grid.
  /// When false, always uses the grid with [mobileCardWidth]/[mobileCardHeight].
  final bool mobilePreferList;

  /// When set (e.g. 2), forces a fixed column count on mobile grid.
  final int? mobileCrossAxisCount;

  const SharedDataTable({
    Key? key,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    this.width,
    this.mobileCardBuilder,
    this.mobileCardWidth = 280,
    this.mobileCardHeight = 168,
    this.mobileCardSpacing = 8,
    this.mobilePreferList = true,
    this.mobileCrossAxisCount,
    this.itemsPerPage = 8,
    this.emptyWidget,
    this.config,
    this.showPagination = true,
    this.enableHorizontalScroll = true,
    this.tableWidth,
    this.paginationLabelBuilder,
    this.header,
  }) : super(key: key);

  @override
  State<SharedDataTable<T>> createState() => _SharedDataTableState<T>();
}

class _SharedDataTableState<T> extends State<SharedDataTable<T>> {
  int _currentPage = 1;

  @override
  void didUpdateWidget(covariant SharedDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _currentPage = 1;
    }
  }

  List<T> get _paginatedItems {
    if (!widget.showPagination) return widget.items;

    final startIndex = (_currentPage - 1) * widget.itemsPerPage;
    final endIndex = startIndex + widget.itemsPerPage;

    if (startIndex >= widget.items.length) return [];
    return widget.items.sublist(
      startIndex,
      endIndex > widget.items.length ? widget.items.length : endIndex,
    );
  }

  int get _totalPages {
    if (!widget.showPagination) return 1;
    return (widget.items.length / widget.itemsPerPage).ceil();
  }

  DataTableConfig get _config =>
      widget.config ?? DataTableConfig.defaultConfig();

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? _buildDefaultEmptyState(context);
    }

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final useMobileCards = isMobile && widget.mobileCardBuilder != null;

    return Container(
      margin:
          useMobileCards
              ? const EdgeInsets.fromLTRB(8, 0, 8, 8)
              : (isMobile ? const EdgeInsets.all(8) : _config.containerMargin),
      decoration: BoxDecoration(
        color: useMobileCards ? Colors.transparent : _config.containerColor,
        borderRadius: _config.containerBorderRadius,
        boxShadow:
            useMobileCards
                ? null
                : (_config.containerShadow ??
                    [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]),
      ),
      child: Column(
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            child: ClipRRect(
              borderRadius:
                  useMobileCards
                      ? BorderRadius.zero
                      : _config.containerBorderRadius,
              child:
                  useMobileCards
                      ? _buildMobileCardView(context)
                      : _buildDesktopView(context, isMobile),
            ),
          ),
          if (widget.showPagination && widget.items.isNotEmpty)
            _buildPaginationFooter(context, isMobile),
        ],
      ),
    );
  }

  /// Mobile: full-width list, or grid (optionally fixed column count).
  Widget _buildMobileCardView(BuildContext context) {
    final builder = widget.mobileCardBuilder!;
    final spacing = widget.mobileCardSpacing;
    final crossAxisCount = widget.mobileCrossAxisCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canFitTwo =
            constraints.maxWidth >=
            (widget.mobileCardWidth * 2 + spacing * 3);
        final forceGrid = crossAxisCount != null && crossAxisCount > 1;
        final useList =
            widget.mobilePreferList && !canFitTwo && !forceGrid;

        if (useList) {
          return ListView.separated(
            padding: EdgeInsets.all(spacing),
            itemCount: _paginatedItems.length,
            separatorBuilder: (_, __) => SizedBox(height: spacing),
            itemBuilder: (context, index) {
              return builder(context, _paginatedItems[index]);
            },
          );
        }

        final SliverGridDelegate gridDelegate =
            forceGrid
                ? SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount!,
                  mainAxisExtent: widget.mobileCardHeight,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                )
                : SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: widget.mobileCardWidth,
                  mainAxisExtent: widget.mobileCardHeight,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                );

        return GridView.builder(
          padding: EdgeInsets.all(spacing),
          gridDelegate: gridDelegate,
          itemCount: _paginatedItems.length,
          itemBuilder: (context, index) {
            return builder(context, _paginatedItems[index]);
          },
        );
      },
    );
  }

  /// Desktop / tablet table with horizontal scroll when needed.
  Widget _buildDesktopView(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final minTableWidth = widget.columns.length * 128.0;
        final tableWidth =
            widget.tableWidth ??
            (availableWidth > minTableWidth ? availableWidth : minTableWidth);

        final table = _buildDataTable(context, isMobile);

        if (!widget.enableHorizontalScroll || availableWidth >= tableWidth) {
          return SingleChildScrollView(
            child: SizedBox(width: availableWidth, child: table),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: SingleChildScrollView(child: table),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(BuildContext context, bool isMobile) {
    return DataTable(
      columnSpacing: _config.columnSpacing,
      horizontalMargin: _config.horizontalMargin,
      headingRowHeight: _config.headingRowHeight,
      dataRowHeight: _config.dataRowHeight,
      headingRowColor: WidgetStateProperty.all(_config.headingRowColor),
      dividerThickness: _config.dividerThickness,
      showCheckboxColumn: _config.showCheckboxColumn,
      columns:
          widget.columns
              .map(
                (col) => _buildColumn(context, col, isMobile, isHeader: true),
              )
              .toList(),
      rows:
          _paginatedItems
              .map((item) => widget.rowBuilder(context, item))
              .toList(),
    );
  }

  DataColumn _buildColumn(
    BuildContext context,
    DataTableColumn column,
    bool isMobile, {
    bool isHeader = false,
  }) {
    final theme = Theme.of(context);
    final onHeading =
        ThemeData.estimateBrightnessForColor(_config.headingRowColor) ==
                Brightness.dark
            ? AppColors.white
            : AppColors.lightText;
    final labelColor = isHeader ? onHeading : theme.colorScheme.onSurface;
    final iconColor = isHeader ? onHeading : theme.colorScheme.onSurfaceVariant;

    return DataColumn(
      label: Row(
        children: [
          if (column.icon != null) ...[
            Icon(column.icon, size: isMobile ? 18 : 18, color: iconColor),
            SizedBox(width: isMobile ? 8 : 8),
          ],
          Text(
            column.label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 14,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final color = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: isMobile ? 100 : 100,
            color: color.withValues(alpha: 0.5),
          ),
          SizedBox(height: isMobile ? 24 : 24),
          Text(
            'لا توجد بيانات',
            style: TextStyle(
              fontSize: isMobile ? 24 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 12),
          Text(
            'سيظهر البيانات هنا',
            style: TextStyle(
              fontSize: isMobile ? 14 : 14,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.colorScheme.outline;
    final useMobileCards =
        isMobile && widget.mobileCardBuilder != null;

    return Container(
      margin: useMobileCards ? const EdgeInsets.fromLTRB(0, 0, 0, 0) : null,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor.withValues(alpha: 0.5)),
        ),
        borderRadius: BorderRadius.circular(useMobileCards ? 12 : (isMobile ? 12 : 12)),
      ),
      child:
          isMobile
              ? Row(
                children: [
                  Expanded(child: _buildResultsInfo(context, isMobile)),
                  _buildPaginationControls(context, isMobile),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildResultsInfo(context, isMobile),
                  _buildPaginationControls(context, isMobile),
                ],
              ),
    );
  }

  Widget _buildResultsInfo(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final from = (_currentPage - 1) * widget.itemsPerPage + 1;
    final to =
        (_currentPage * widget.itemsPerPage) > widget.items.length
            ? widget.items.length
            : (_currentPage * widget.itemsPerPage);

    final label =
        widget.paginationLabelBuilder != null
            ? widget.paginationLabelBuilder!(from, to, widget.items.length)
            : 'Showing $from to $to of ${widget.items.length} results';

    return Text(
      label,
      style: TextStyle(
        fontSize: isMobile ? 12 : 14,
        color: theme.colorScheme.onSurface,
      ),
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildPaginationControls(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final disabledColor = theme.colorScheme.outline;

    return Row(
      mainAxisAlignment:
          isMobile ? MainAxisAlignment.center : MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed:
              _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          icon: const Icon(Icons.chevron_left),
          iconSize: isMobile ? 20 : 24,
          style: IconButton.styleFrom(
            backgroundColor:
                _currentPage > 1
                    ? primaryColor.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest,
            foregroundColor: _currentPage > 1 ? primaryColor : disabledColor,
            padding: isMobile ? EdgeInsets.all(8) : null,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 8),
        ..._buildPageNumbers(context, isMobile),
        SizedBox(width: isMobile ? 8 : 8),
        IconButton(
          onPressed:
              _currentPage < _totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
          icon: const Icon(Icons.chevron_right),
          iconSize: isMobile ? 20 : 24,
          style: IconButton.styleFrom(
            backgroundColor:
                _currentPage < _totalPages
                    ? primaryColor.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest,
            foregroundColor:
                _currentPage < _totalPages ? primaryColor : disabledColor,
            padding: isMobile ? EdgeInsets.all(8) : null,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    List<Widget> pages = [];

    for (int i = 1; i <= _totalPages; i++) {
      if (i == _currentPage ||
          i == 1 ||
          i == _totalPages ||
          (i >= _currentPage - 1 && i <= _currentPage + 1)) {
        pages.add(_buildPageButton(context, i, isMobile));
      } else if (i == _currentPage - 2 || i == _currentPage + 2) {
        if (!isMobile) {
          pages.add(
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '...',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }
      }
    }

    return pages;
  }

  Widget _buildPageButton(BuildContext context, int pageNumber, bool isMobile) {
    final theme = Theme.of(context);
    final isActive = pageNumber == _currentPage;
    final primaryColor = theme.colorScheme.primary;
    final borderColor = theme.colorScheme.outline;

    return InkWell(
      onTap: () => setState(() => _currentPage = pageNumber),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(isMobile ? 8 : 8),
          border: Border.all(
            color: isActive ? primaryColor : borderColor,
            width: 1,
          ),
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            color:
                isActive
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
      ),
    );
  }
}

/// Column definition for DataTable
class DataTableColumn {
  final String label;
  final IconData? icon;

  const DataTableColumn({required this.label, this.icon});
}

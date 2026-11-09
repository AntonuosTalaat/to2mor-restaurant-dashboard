import 'package:flutter/material.dart';

class DataTableConfig {
  // Container styling
  final EdgeInsets containerMargin;
  final Color containerColor;
  final BorderRadius containerBorderRadius;
  final List<BoxShadow>? containerShadow;

  // Table dimensions
  final double columnSpacing;
  final double horizontalMargin;
  final double headingRowHeight;
  final double dataRowHeight;

  // Table styling
  final Color headingRowColor;
  final double dividerThickness;
  final bool showCheckboxColumn;

  const DataTableConfig({
    this.containerMargin = const EdgeInsets.all(16),
    this.containerColor = Colors.white,
    BorderRadius? containerBorderRadius,
    this.containerShadow,
    this.columnSpacing = 0.5,
    this.horizontalMargin = 8,
    this.headingRowHeight = 70,
    this.dataRowHeight = 100,
    Color? headingRowColor,
    this.dividerThickness = 1,
    this.showCheckboxColumn = false,
  }) : containerBorderRadius =
           containerBorderRadius ?? const BorderRadius.all(Radius.circular(12)),
       headingRowColor = headingRowColor ?? const Color(0xFFFAFAFA);

  /// Default configuration
  factory DataTableConfig.defaultConfig() {
    return DataTableConfig(
      containerMargin: EdgeInsets.all(16),
      containerColor: Colors.white,
      containerBorderRadius: BorderRadius.circular(12),
      containerShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      // مسافات مريحة بين الأعمدة وتعمل جيداً مع الموبايل
      columnSpacing: 12,
      horizontalMargin: 12,
      headingRowHeight: 56,
      dataRowHeight: 64,
      headingRowColor: Colors.grey[50]!,
      dividerThickness: 1,
      showCheckboxColumn: false,
    );
  }

  /// Compact configuration
  factory DataTableConfig.compact() {
    return DataTableConfig(
      containerMargin: EdgeInsets.all(8),
      headingRowHeight: 48,
      dataRowHeight: 56,
      // تقليل المسافة بين الأعمدة قدر الإمكان
      columnSpacing: 8,
      horizontalMargin: 8,
    );
  }

  /// Custom configuration
  DataTableConfig copyWith({
    EdgeInsets? containerMargin,
    Color? containerColor,
    BorderRadius? containerBorderRadius,
    List<BoxShadow>? containerShadow,
    double? columnSpacing,
    double? horizontalMargin,
    double? headingRowHeight,
    double? dataRowHeight,
    Color? headingRowColor,
    double? dividerThickness,
    bool? showCheckboxColumn,
  }) {
    return DataTableConfig(
      containerMargin: containerMargin ?? this.containerMargin,
      containerColor: containerColor ?? this.containerColor,
      containerBorderRadius:
          containerBorderRadius ?? this.containerBorderRadius,
      containerShadow: containerShadow ?? this.containerShadow,
      columnSpacing: columnSpacing ?? this.columnSpacing,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      headingRowHeight: headingRowHeight ?? this.headingRowHeight,
      dataRowHeight: dataRowHeight ?? this.dataRowHeight,
      headingRowColor: headingRowColor ?? this.headingRowColor,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      showCheckboxColumn: showCheckboxColumn ?? this.showCheckboxColumn,
    );
  }
}

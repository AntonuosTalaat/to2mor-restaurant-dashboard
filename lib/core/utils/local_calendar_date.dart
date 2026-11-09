import 'package:flutter/material.dart';

/// Device [DateTime] values may be UTC or local; Firestore [Timestamp.toDate]
/// is local on mobile but treat consistently via [toLocal] for day bucketing.

DateTime startOfLocalDay(DateTime date) {
  final l = date.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Inclusive local calendar days from [firstInstant] through [lastInstant].
bool isLocalDayBetween(
  DateTime orderDate,
  DateTime firstInstant,
  DateTime lastInstant,
) {
  final od = startOfLocalDay(orderDate);
  final first = startOfLocalDay(firstInstant);
  final last = startOfLocalDay(lastInstant);
  return !od.isBefore(first) && !od.isAfter(last);
}

extension OrderDateRangeX on DateTimeRange {
  /// Whether [orderDate] lies on any calendar day from [start] through [end] (local).
  bool containsOrderLocalDay(DateTime orderDate) =>
      isLocalDayBetween(orderDate, start, end);
}

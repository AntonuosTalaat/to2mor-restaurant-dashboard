import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class DateRangeDialog {
  static Future<DateTimeRange?> show(
      BuildContext context, {
        DateTimeRange? initialRange,
      }) async {
    DateTime? tempStartDate = initialRange?.start;
    DateTime? tempEndDate = initialRange?.end;

    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text(
                  'اختر الفترة الزمنية',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                content: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // من تاريخ
                      _dateField(
                        context: context,
                        label: "من تاريخ",
                        icon: Icons.calendar_today,
                        date: tempStartDate,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: tempEndDate ?? DateTime.now(),
                            builder: _pickerBuilder(context),
                            helpText: 'اختر تاريخ البداية',
                            cancelText: 'إلغاء',
                            confirmText: 'تأكيد',
                          );
                          if (picked != null) {
                            setDialogState(() {
                              tempStartDate = picked;
                              if (tempEndDate != null &&
                                  tempEndDate!.isBefore(picked)) {
                                tempEndDate = picked;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // إلى تاريخ
                      _dateField(
                        context: context,
                        label: "إلى تاريخ",
                        icon: Icons.event,
                        date: tempEndDate,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                            tempEndDate ?? tempStartDate ?? DateTime.now(),
                            firstDate: tempStartDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: _pickerBuilder(context),
                            helpText: 'اختر تاريخ النهاية',
                            cancelText: 'إلغاء',
                            confirmText: 'تأكيد',
                          );
                          if (picked != null) {
                            setDialogState(() => tempEndDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // خيارات سريعة
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quickOption(context, "اليوم", () {
                            final now = DateTime.now();
                            setDialogState(() {
                              tempStartDate =
                                  DateTime(now.year, now.month, now.day);
                              tempEndDate =
                                  DateTime(now.year, now.month, now.day);
                            });
                          }),
                          _quickOption(context, "أمس", () {
                            final y = DateTime.now()
                                .subtract(const Duration(days: 1));
                            setDialogState(() {
                              tempStartDate =
                                  DateTime(y.year, y.month, y.day);
                              tempEndDate =
                                  DateTime(y.year, y.month, y.day);
                            });
                          }),
                          _quickOption(context, "آخر 7 أيام", () {
                            final now = DateTime.now();
                            final w = now.subtract(const Duration(days: 6));
                            setDialogState(() {
                              tempStartDate = DateTime(w.year, w.month, w.day);
                              tempEndDate =
                                  DateTime(now.year, now.month, now.day);
                            });
                          }),
                          _quickOption(context, "آخر 30 يوم", () {
                            final now = DateTime.now();
                            final m = now.subtract(const Duration(days: 29));
                            setDialogState(() {
                              tempStartDate = DateTime(m.year, m.month, m.day);
                              tempEndDate =
                                  DateTime(now.year, now.month, now.day);
                            });
                          }),
                          _quickOption(context, "هذا الشهر", () {
                            final now = DateTime.now();
                            setDialogState(() {
                              tempStartDate = DateTime(now.year, now.month, 1);
                              tempEndDate =
                                  DateTime(now.year, now.month, now.day);
                            });
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: tempStartDate != null && tempEndDate != null
                        ? () {
                      Navigator.of(dialogContext).pop(
                        DateTimeRange(
                          start: tempStartDate!,
                          end: DateTime(
                            tempEndDate!.year,
                            tempEndDate!.month,
                            tempEndDate!.day,
                            23,
                            59,
                            59,
                          ),
                        ),
                      );
                    }
                        : null,
                    child: const Text('تأكيد'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    return result;
  }

  static Widget _dateField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('yyyy/MM/dd').format(date)
                        : "اختر التاريخ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: date != null ? Colors.black : Colors.grey,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  static Widget _quickOption(
      BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static Widget Function(BuildContext, Widget?) _pickerBuilder(
      BuildContext context) {
    return (context, child) {
      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        ),
      );
    };
  }
}

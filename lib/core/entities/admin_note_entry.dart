import 'package:flutter/material.dart';

enum AdminNoteCategory {
  admins,
  delivery,
  users;

  String get firestoreKey => switch (this) {
        AdminNoteCategory.admins => 'adminNotesforadmins',
        AdminNoteCategory.delivery => 'adminNotesForDelivery',
        AdminNoteCategory.users => 'adminNotesForusers',
      };

  String get label => switch (this) {
        AdminNoteCategory.admins => 'ملاحظات داخلية (للإدارة)',
        AdminNoteCategory.delivery => 'ملاحظات للمندوب',
        AdminNoteCategory.users => 'ملاحظات للعميل',
      };

  String get hint => switch (this) {
        AdminNoteCategory.admins => 'أضف ملاحظة للإدارة فقط...',
        AdminNoteCategory.delivery => 'أضف تعليمات للمندوب...',
        AdminNoteCategory.users => 'أضف ملاحظة للعميل...',
      };

  IconData get icon => switch (this) {
        AdminNoteCategory.admins => Icons.shield_outlined,
        AdminNoteCategory.delivery => Icons.delivery_dining_outlined,
        AdminNoteCategory.users => Icons.person_outline,
      };
}

class AdminNoteEntry {
  const AdminNoteEntry({
    required this.text,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
  });

  final String text;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'text': text,
        'createdById': createdById,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AdminNoteEntry.fromMap(Map<String, dynamic> map) {
    return AdminNoteEntry(
      text: map['text']?.toString() ?? '',
      createdById: map['createdById']?.toString() ?? '',
      createdByName: map['createdByName']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static List<AdminNoteEntry> listFromFirestore(dynamic raw) {
    if (raw == null) return [];

    if (raw is String && raw.trim().isNotEmpty) {
      return [
        AdminNoteEntry(
          text: raw.trim(),
          createdById: '',
          createdByName: 'ملاحظة سابقة',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ];
    }

    if (raw is! List) return [];

    return raw
        .map((e) => AdminNoteEntry.fromMap(Map<String, dynamic>.from(e)))
        .where((e) => e.text.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

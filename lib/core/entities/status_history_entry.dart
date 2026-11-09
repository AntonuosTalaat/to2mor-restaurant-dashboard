class StatusHistoryEntry {
  final String status;
  final String changedById;
  final String changedByName;
  final DateTime changedAt;

  const StatusHistoryEntry({
    required this.status,
    required this.changedById,
    required this.changedByName,
    required this.changedAt,
  });

  Map<String, dynamic> toMap() => {
        'status': status,
        'changedById': changedById,
        'changedByName': changedByName,
        'changedAt': changedAt.toIso8601String(),
      };

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      status: map['status']?.toString() ?? '',
      changedById: map['changedById']?.toString() ?? '',
      changedByName: map['changedByName']?.toString() ?? '',
      changedAt: DateTime.tryParse(map['changedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static List<StatusHistoryEntry> listFromFirestore(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => StatusHistoryEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
  }
}

StatusHistoryEntry? findStatusHistoryEntry(
  List<StatusHistoryEntry> history,
  String status,
) {
  for (var i = history.length - 1; i >= 0; i--) {
    if (history[i].status == status) return history[i];
  }
  return null;
}

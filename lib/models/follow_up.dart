/// Step 12: FollowUp UI model with Supabase mapping.
class FollowUp {
  final String id; // uuid from Supabase, or local millis key in fallback mode
  final String? patientId;
  final String patientName;
  final String dateIso; // yyyy-MM-dd (public.follow_ups.follow_up_date)
  final String dateLabel; // display label, e.g. "25 May 2025"
  final String time; // public.follow_ups.follow_up_time
  final String notes;
  final bool isDone;

  // Step 11/12: backend identity + timestamps (null in local fallback mode).
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FollowUp({
    required this.id,
    this.patientId,
    required this.patientName,
    required this.dateIso,
    required this.dateLabel,
    required this.time,
    required this.notes,
    this.isDone = false,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'patientName': patientName,
    'dateIso': dateIso,
    'dateLabel': dateLabel,
    'time': time,
    'notes': notes,
    'isDone': isDone,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory FollowUp.fromMap(Map<String, dynamic> map) => FollowUp(
    id: map['id'] as String,
    patientId: map['patientId'] as String?,
    patientName: (map['patientName'] ?? '') as String,
    dateIso: (map['dateIso'] ?? '') as String,
    dateLabel: (map['dateLabel'] ?? '') as String,
    time: (map['time'] ?? '') as String,
    notes: (map['notes'] ?? '') as String,
    isDone: (map['isDone'] ?? false) as bool,
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
    updatedAt: map['updatedAt'] == null
        ? null
        : DateTime.tryParse(map['updatedAt'] as String),
  );

  /// Row from `public.follow_ups` -> UI model.
  factory FollowUp.fromSupabase(Map<String, dynamic> row) {
    final iso = (row['follow_up_date'] ?? '') as String;
    final parsed = iso.isNotEmpty ? DateTime.tryParse(iso) : null;
    return FollowUp(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String?,
      patientId: row['patient_id'] as String?,
      patientName: (row['patient_name'] ?? '') as String,
      dateIso: iso,
      dateLabel: parsed == null ? iso : formatDisplayDate(parsed),
      time: (row['follow_up_time'] ?? '') as String,
      notes: (row['notes'] ?? '') as String,
      isDone: (row['is_done'] ?? false) as bool,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse(row['created_at'] as String),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.tryParse(row['updated_at'] as String),
    );
  }

  /// UI model -> `public.follow_ups` insert payload.
  /// `id` omitted so Postgres assigns `gen_random_uuid()`.
  /// `patient_id` sent only when it is a real uuid (FK to patients);
  /// legacy local ids are dropped to null, `patient_name` is kept.
  Map<String, dynamic> toSupabase({required String ownerId}) {
    var iso = dateIso.trim();
    if (iso.isEmpty) {
      final now = DateTime.now();
      iso = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
    }
    return {
      'owner_id': ownerId,
      'patient_id': isUuid(patientId) ? patientId : null,
      'patient_name': patientName.trim(),
      'follow_up_date': iso,
      'follow_up_time': time,
      'notes': notes,
      'is_done': isDone,
    };
  }

  static bool isUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  static String formatDisplayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  FollowUp copyWith({bool? isDone}) => FollowUp(
    id: id,
    patientId: patientId,
    patientName: patientName,
    dateIso: dateIso,
    dateLabel: dateLabel,
    time: time,
    notes: notes,
    isDone: isDone ?? this.isDone,
    ownerId: ownerId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

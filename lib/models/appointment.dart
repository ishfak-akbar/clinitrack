/// Step 12: Appointment UI model with Supabase mapping.
class Appointment {
  final String id; // uuid from Supabase, or local millis key in fallback mode
  final String? patientId;
  final String patientName;
  final String date;
  final String dateIso;
  final String time;
  final String reason;
  /// Display snapshot of the doctor's name (offline + list rendering).
  /// Never use for matching — [ownerId] is the canonical doctor reference
  /// (`appointments.owner_id`). Names drift when a doctor edits their
  /// profile; ids don't.
  final String doctor;
  final String status;

  // Step 10/12: backend identity + timestamps (null in local fallback mode).
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Canonical doctor reference — alias of [ownerId] for call-site clarity.
  /// Prefer this over [doctor] whenever comparing "same doctor?".
  String? get doctorId => ownerId;

  /// True when both rows belong to the same doctor. Falls back to the
  /// display-name snapshot only for legacy local rows with no owner id.
  bool isSameDoctor(Appointment other) {
    if (ownerId != null &&
        ownerId!.isNotEmpty &&
        other.ownerId != null &&
        other.ownerId!.isNotEmpty) {
      return ownerId == other.ownerId;
    }
    return doctor.trim().toLowerCase() ==
        other.doctor.trim().toLowerCase();
  }

  Appointment({
    required this.id,
    this.patientId,
    required this.patientName,
    required this.date,
    required this.dateIso,
    required this.time,
    required this.reason,
    required this.doctor,
    required this.status,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'patientName': patientName,
    'date': date,
    'dateIso': dateIso,
    'time': time,
    'reason': reason,
    'doctor': doctor,
    'status': status,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Appointment.fromMap(Map<String, dynamic> map) => Appointment(
    id: map['id'] as String,
    patientId: map['patientId'] as String?,
    patientName: (map['patientName'] ?? '') as String,
    date: (map['date'] ?? '') as String,
    dateIso: (map['dateIso'] ?? '') as String,
    time: (map['time'] ?? '') as String,
    reason: (map['reason'] ?? '') as String,
    doctor: (map['doctor'] ?? '') as String,
    status: (map['status'] ?? 'scheduled') as String,
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
    updatedAt: map['updatedAt'] == null
        ? null
        : DateTime.tryParse(map['updatedAt'] as String),
  );

  /// Row from `public.appointments` -> UI model.
  factory Appointment.fromSupabase(Map<String, dynamic> row) {
    final iso = (row['date_iso'] ?? '') as String;
    var label = (row['date_label'] ?? '') as String;
    if (label.isEmpty && iso.isNotEmpty) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) label = formatDisplayDate(parsed);
    }
    return Appointment(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String?,
      patientId: row['patient_id'] as String?,
      patientName: (row['patient_name'] ?? '') as String,
      date: label,
      dateIso: iso,
      time: (row['time_text'] ?? '') as String,
      reason: (row['reason'] ?? '') as String,
      doctor: (row['doctor_name'] ?? '') as String,
      status: (row['status'] ?? 'scheduled') as String,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse(row['created_at'] as String),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.tryParse(row['updated_at'] as String),
    );
  }

  /// UI model -> `public.appointments` insert payload.
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
    var label = date.trim();
    if (label.isEmpty) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) label = formatDisplayDate(parsed);
    }
    return {
      'owner_id': ownerId,
      'patient_id': isUuid(patientId) ? patientId : null,
      'patient_name': patientName.trim(),
      'date_iso': iso,
      'date_label': label,
      'time_text': time,
      'reason': reason,
      'doctor_name': doctor,
      'status': status.isEmpty ? 'scheduled' : status,
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

  Appointment copyWith({String? status}) => Appointment(
    id: id,
    patientId: patientId,
    patientName: patientName,
    date: date,
    dateIso: dateIso,
    time: time,
    reason: reason,
    doctor: doctor,
    status: status ?? this.status,
    ownerId: ownerId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Step 12: Prescription UI model with Supabase mapping.
class Prescription {
  final String id; // uuid from Supabase, or local millis key in fallback mode
  final String patientId;
  final String medicineName;
  final String dosage;
  final String duration;
  final String frequency;
  final String notes;

  // Step 11/12: backend identity + timestamps (null in local fallback mode).
  final String? ownerId;
  final DateTime? createdAt;

  Prescription({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.duration,
    required this.frequency,
    required this.notes,
    this.ownerId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'medicineName': medicineName,
    'dosage': dosage,
    'duration': duration,
    'frequency': frequency,
    'notes': notes,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Prescription.fromMap(Map<String, dynamic> map) => Prescription(
    id: map['id'] as String,
    patientId: (map['patientId'] ?? '') as String,
    medicineName: (map['medicineName'] ?? '') as String,
    dosage: (map['dosage'] ?? '') as String,
    duration: (map['duration'] ?? '') as String,
    frequency: (map['frequency'] ?? 'Daily') as String,
    notes: (map['notes'] ?? '') as String,
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
  );

  /// Row from `public.prescriptions` -> UI model.
  /// DB columns: patient_id uuid?, medicine_name, dosage, duration_text,
  /// frequency, notes, owner_id, created_at.
  factory Prescription.fromSupabase(Map<String, dynamic> row) => Prescription(
    id: row['id'] as String,
    ownerId: row['owner_id'] as String?,
    patientId: (row['patient_id'] ?? '') as String,
    medicineName: (row['medicine_name'] ?? '') as String,
    dosage: (row['dosage'] ?? '') as String,
    duration: (row['duration_text'] ?? '') as String,
    frequency: (row['frequency'] ?? 'Daily') as String,
    notes: (row['notes'] ?? '') as String,
    createdAt: row['created_at'] == null
        ? null
        : DateTime.tryParse(row['created_at'] as String),
  );

  /// UI model -> `public.prescriptions` insert payload.
  /// `id` omitted so Postgres assigns `gen_random_uuid()`.
  /// `patient_id` sent only when it is a real uuid (FK to patients);
  /// legacy local ids are dropped to null.
  Map<String, dynamic> toSupabase({required String ownerId}) => {
    'owner_id': ownerId,
    'patient_id': isUuid(patientId) ? patientId : null,
    'medicine_name': medicineName.trim(),
    'dosage': dosage,
    'duration_text': duration,
    'frequency': frequency.isEmpty ? 'Daily' : frequency,
    'notes': notes,
  };

  static bool isUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String get summary => '$medicineName $dosage — $frequency, $duration';
}

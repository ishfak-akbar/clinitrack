/// Step 12: Medicine + MedicineOrder UI models with Supabase mapping.
class Medicine {
  final String id; // uuid from Supabase, or local millis key in fallback mode
  final String name;
  final String category;
  final int stock;
  final String unit;

  // Step 11/12: backend identity + timestamps (null in local fallback mode).
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.unit,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'stock': stock,
    'unit': unit,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
    id: map['id'] as String,
    name: (map['name'] ?? '') as String,
    category: (map['category'] ?? 'General') as String,
    stock: (map['stock'] as num? ?? 0).toInt(),
    unit: (map['unit'] ?? 'tablets') as String,
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
    updatedAt: map['updatedAt'] == null
        ? null
        : DateTime.tryParse(map['updatedAt'] as String),
  );

  /// Row from `public.medicines` -> UI model.
  factory Medicine.fromSupabase(Map<String, dynamic> row) => Medicine(
    id: row['id'] as String,
    ownerId: row['owner_id'] as String?,
    name: (row['name'] ?? '') as String,
    category: (row['category'] ?? 'General') as String,
    stock: (row['stock'] as num? ?? 0).toInt(),
    unit: (row['unit'] ?? 'tablets') as String,
    createdAt: row['created_at'] == null
        ? null
        : DateTime.tryParse(row['created_at'] as String),
    updatedAt: row['updated_at'] == null
        ? null
        : DateTime.tryParse(row['updated_at'] as String),
  );

  /// UI model -> `public.medicines` insert payload.
  /// `id` omitted so Postgres assigns `gen_random_uuid()`.
  /// `unique(owner_id, name)` is enforced in Postgres.
  Map<String, dynamic> toSupabase({required String ownerId}) => {
    'owner_id': ownerId,
    'name': name.trim(),
    'category': category.isEmpty ? 'General' : category,
    'stock': stock < 0 ? 0 : stock,
    'unit': unit.isEmpty ? 'tablets' : unit,
  };

  Medicine copyWith({int? stock}) => Medicine(
    id: id,
    name: name,
    category: category,
    stock: stock ?? this.stock,
    unit: unit,
    ownerId: ownerId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class MedicineOrder {
  final String id;
  final String? medicineId;
  final String medicineName;
  final int quantity;

  final String? ownerId;
  final DateTime? createdAt;

  MedicineOrder({
    required this.id,
    this.medicineId,
    required this.medicineName,
    required this.quantity,
    this.ownerId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'medicineId': medicineId,
    'medicineName': medicineName,
    'quantity': quantity,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory MedicineOrder.fromMap(Map<String, dynamic> map) => MedicineOrder(
    id: map['id'] as String,
    medicineId: map['medicineId'] as String?,
    medicineName: (map['medicineName'] ?? '') as String,
    quantity: (map['quantity'] as num? ?? 0).toInt(),
    ownerId: map['ownerId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.tryParse(map['createdAt'] as String),
  );

  /// Row from `public.medicine_orders` -> UI model.
  factory MedicineOrder.fromSupabase(Map<String, dynamic> row) =>
      MedicineOrder(
        id: row['id'] as String,
        medicineId: row['medicine_id'] as String?,
        medicineName: (row['medicine_name'] ?? '') as String,
        quantity: (row['quantity'] as num? ?? 0).toInt(),
        ownerId: row['owner_id'] as String?,
        createdAt: row['created_at'] == null
            ? null
            : DateTime.tryParse(row['created_at'] as String),
      );
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';

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

class FollowUpProvider extends ChangeNotifier {
  static const String _key = 'follow_ups_list';

  List<FollowUp> _followUps = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<FollowUp> get followUps => _followUps;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => SupabaseConfig.isConfigured;
  String? get _userId => useBackend
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  List<FollowUp> forPatient(String patientId) {
    final items = _followUps
        .where((f) => f.patientId == patientId || f.patientName.isNotEmpty && patientId.isEmpty)
        .toList();
    items.sort((a, b) => a.dateIso.compareTo(b.dateIso));
    return items;
  }

  List<FollowUp> get pending {
    final items = _followUps.where((f) => !f.isDone).toList();
    items.sort((a, b) => a.dateIso.compareTo(b.dateIso));
    return items;
  }

  Future<void> loadFollowUps() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (useBackend) {
        await _loadFromSupabase();
      } else {
        await _loadLocal();
      }
    } catch (_) {
      _errorMessage =
          'Could not load follow-ups. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromSupabase() async {
    final userId = _userId;
    if (userId == null) {
      _followUps = [];
      return;
    }
    final rows = await SupabaseConfig.client
        .from('follow_ups')
        .select()
        .order('follow_up_date', ascending: true);
    _followUps = (rows as List)
        .map((r) => FollowUp.fromSupabase(r as Map<String, dynamic>))
        .toList();
  }

  /// Local fallback when Supabase is not configured (fresh clone / offline).
  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    _followUps = rawList
        .map((raw) => FollowUp.fromMap(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<bool> addFollowUp(FollowUp followUp) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add a follow-up.';
        notifyListeners();
        return false;
      }
      try {
        final row = await SupabaseConfig.client
            .from('follow_ups')
            .insert(followUp.toSupabase(ownerId: userId))
            .select()
            .single();
        _followUps.insert(0, FollowUp.fromSupabase(row));
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage =
            'Could not save follow-up. Check connection and try again.';
        notifyListeners();
        return false;
      }
    }

    final label = followUp.dateLabel.isEmpty && followUp.dateIso.isNotEmpty
        ? _labelForIso(followUp.dateIso)
        : followUp.dateLabel;
    _followUps.insert(
      0,
      followUp.id.isEmpty
          ? FollowUp(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              patientId: followUp.patientId,
              patientName: followUp.patientName,
              dateIso: followUp.dateIso,
              dateLabel: label,
              time: followUp.time,
              notes: followUp.notes,
              isDone: followUp.isDone,
            )
          : followUp,
    );
    notifyListeners();
    await _persistLocal();
    return true;
  }

  Future<bool> toggleDone(String id, bool isDone) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await SupabaseConfig.client
            .from('follow_ups')
            .update({'is_done': isDone})
            .eq('id', id);
        final index = _followUps.indexWhere((f) => f.id == id);
        if (index != -1) {
          _followUps[index] = _followUps[index].copyWith(isDone: isDone);
          notifyListeners();
        }
        return true;
      } catch (_) {
        _errorMessage = 'Could not update follow-up. Try again.';
        notifyListeners();
        return false;
      }
    }

    final index = _followUps.indexWhere((f) => f.id == id);
    if (index == -1) return false;
    _followUps[index] = _followUps[index].copyWith(isDone: isDone);
    notifyListeners();
    await _persistLocal();
    return true;
  }

  Future<bool> deleteFollowUp(String id) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await SupabaseConfig.client.from('follow_ups').delete().eq('id', id);
        _followUps.removeWhere((f) => f.id == id);
        notifyListeners();
        return true;
      } catch (_) {
        _errorMessage = 'Could not delete follow-up. Try again.';
        notifyListeners();
        return false;
      }
    }

    _followUps.removeWhere((f) => f.id == id);
    notifyListeners();
    await _persistLocal();
    return true;
  }

  /// Clears in-memory list (e.g. on logout so the next account
  /// never briefly sees the previous account's follow-ups).
  void clearCache() {
    _followUps = [];
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _followUps.map((f) => jsonEncode(f.toMap())).toList();
    await prefs.setStringList(_key, rawList);
  }

  static String _labelForIso(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return FollowUp.formatDisplayDate(parsed);
  }
}

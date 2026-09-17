import 'package:flutter/material.dart';

import '../models/follow_up.dart';
import '../repositories/follow_up_repository.dart';

export '../models/follow_up.dart';

/// Step 14: UI state only — all data access goes through [FollowUpRepository].
class FollowUpProvider extends ChangeNotifier {
  final FollowUpRepository _repo = FollowUpRepository();

  List<FollowUp> _followUps = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<FollowUp> get followUps => _followUps;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get useBackend => _repo.useBackend;

  List<FollowUp> forPatient(String patientId) {
    final items =
        _followUps.where((f) => f.patientId == patientId).toList();
    items.sort((a, b) => a.dateIso.compareTo(b.dateIso));
    return items;
  }

  List<FollowUp> get pending {
    final items = _followUps.where((f) => !f.isDone).toList();
    items.sort((a, b) => a.dateIso.compareTo(b.dateIso));
    return items;
  }

  List<FollowUp> get completed {
    final items = _followUps.where((f) => f.isDone).toList();
    items.sort((a, b) => b.dateIso.compareTo(a.dateIso));
    return items;
  }

  Future<void> loadFollowUps() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (useBackend) {
        if (_repo.userId == null) {
          _followUps = [];
        } else {
          _followUps = await _repo.fetchAll();
        }
      } else {
        _followUps = await _repo.loadLocal();
      }
    } catch (_) {
      _errorMessage =
          'Could not load follow-ups. Check connection and try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addFollowUp(FollowUp followUp) async {
    _errorMessage = '';
    if (useBackend) {
      final userId = _repo.userId;
      if (userId == null) {
        _errorMessage = 'Please sign in again to add a follow-up.';
        notifyListeners();
        return false;
      }
      try {
        final saved = await _repo.insert(followUp, userId);
        _followUps.insert(0, saved);
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
    await _repo.saveLocal(_followUps);
    return true;
  }

  Future<bool> toggleDone(String id, bool isDone) async {
    _errorMessage = '';
    if (useBackend) {
      if (_repo.userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await _repo.updateDone(id, isDone);
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
    await _repo.saveLocal(_followUps);
    return true;
  }

  Future<bool> deleteFollowUp(String id) async {
    _errorMessage = '';
    if (useBackend) {
      if (_repo.userId == null) {
        _errorMessage = 'Please sign in again.';
        notifyListeners();
        return false;
      }
      try {
        await _repo.delete(id);
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
    await _repo.saveLocal(_followUps);
    return true;
  }

  /// Clears in-memory list (e.g. on logout so the next account
  /// never briefly sees the previous account's follow-ups).
  void clearCache() {
    _followUps = [];
    _errorMessage = '';
    notifyListeners();
  }

  static String _labelForIso(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return FollowUp.formatDisplayDate(parsed);
  }
}

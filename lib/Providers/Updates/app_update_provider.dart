import 'package:flutter/material.dart';
import '../../Model/Updates/app_update_model.dart';
import '../../Repository/Updates/app_update_repository.dart';

class AppUpdateProvider extends ChangeNotifier {
  final AppUpdateRepository _repository = AppUpdateRepository();

  List<AppUpdateModel> _updates = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedAppFilter = 'all';
  String _selectedStatusFilter = 'all'; // 'all', 'active', 'inactive'
  String _selectedCriticalFilter = 'all'; // 'all', 'critical', 'normal'

  List<AppUpdateModel> get updates => _updates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedAppFilter => _selectedAppFilter;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedCriticalFilter => _selectedCriticalFilter;

  int get totalCount => _updates.length;
  int get activeCount => _updates.where((u) => u.isActive).length;
  int get criticalCount => _updates.where((u) => u.isActive && u.isCritical).length;

  List<AppUpdateModel> get filteredUpdates {
    return _updates.where((update) {
      final matchesSearch = _searchQuery.isEmpty ||
          update.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          update.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          update.targetAppName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesApp = _selectedAppFilter == 'all' || update.targetApp == _selectedAppFilter;

      final matchesStatus = _selectedStatusFilter == 'all' ||
          (_selectedStatusFilter == 'active' && update.isActive) ||
          (_selectedStatusFilter == 'inactive' && !update.isActive);

      final matchesCritical = _selectedCriticalFilter == 'all' ||
          (_selectedCriticalFilter == 'critical' && update.isCritical) ||
          (_selectedCriticalFilter == 'normal' && !update.isCritical);

      return matchesSearch && matchesApp && matchesStatus && matchesCritical;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setAppFilter(String appKey) {
    _selectedAppFilter = appKey;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setCriticalFilter(String crit) {
    _selectedCriticalFilter = crit;
    notifyListeners();
  }

  Future<void> fetchUpdates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _updates = await _repository.getAllUpdates();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUpdate(AppUpdateModel newUpdate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _repository.createUpdate(newUpdate);
      final updateWithId = newUpdate.copyWith(id: id);
      _updates.insert(0, updateWithId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNotification(AppUpdateModel update) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.updateNotification(update);
      if (success) {
        final index = _updates.indexWhere((u) => u.id == update.id);
        if (index != -1) {
          _updates[index] = update;
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleActiveStatus(String updateId, bool newStatus) async {
    try {
      final success = await _repository.toggleActiveStatus(updateId, newStatus);
      if (success) {
        final index = _updates.indexWhere((u) => u.id == updateId);
        if (index != -1) {
          _updates[index] = _updates[index].copyWith(isActive: newStatus);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUpdate(String updateId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.deleteUpdate(updateId);
      if (success) {
        _updates.removeWhere((u) => u.id == updateId);
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

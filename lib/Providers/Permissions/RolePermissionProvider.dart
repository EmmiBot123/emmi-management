import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../Model/Permissions/RolePermissionModel.dart';

class RolePermissionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, RolePermissionModel> _permissionsByRole = {};
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _subscription;

  Map<String, RolePermissionModel> get permissionsByRole => _permissionsByRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('role_permissions');

  static const List<String> supportedRoles = [
    'ADMIN',
    'ASSEMBLY_TEAM',
    'INSTALLATION_TEAM',
    'ACCOUNTS',
    'MARKETING',
    'TELE_MARKETING',
    'DIGITAL_MARKETING',
    'QUBIQ',
    'ADS',
    'TESTING',
    'DEPLOYMENT',
    'TUTORIALS',
  ];

  RolePermissionProvider() {
    initRealtimeListener();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void initRealtimeListener() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _collection.snapshots().listen(
      (snapshot) {
        _permissionsByRole.clear();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final model = RolePermissionModel.fromJson(data, doc.id);
          _permissionsByRole[model.roleKey.toUpperCase()] = model;
        }
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to role_permissions: $error');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  RolePermissionModel getPermissionForRole(String roleKey) {
    final key = roleKey.trim().toUpperCase();
    if (_permissionsByRole.containsKey(key)) {
      return _permissionsByRole[key]!;
    }
    return RolePermissionModel.defaultForRole(key);
  }

  bool canUserAccessScreen(String userRolesString, String screenName) {
    final rolesList = userRolesString
        .split(',')
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();

    if (rolesList.contains('SUPER_ADMIN')) {
      if (screenName == 'CEO Dashboard' ||
          screenName == 'Assistant Dashboard' ||
          screenName == 'Deployment Dashboard' ||
          screenName == 'Tutorials') {
        return false;
      }
      return true;
    }

    if (rolesList.contains('CEO')) {
      return screenName == 'CEO Dashboard';
    }

    if (rolesList.contains('ASSISTANT')) {
      return screenName == 'Assistant Dashboard';
    }

    for (final role in rolesList) {
      final perm = getPermissionForRole(role);
      if (perm.canAccessRoleScreen(screenName)) {
        return true;
      }
    }

    return false;
  }

  bool userHasCapability(
    String userRolesString,
    bool Function(RolePermissionModel perm) predicate,
  ) {
    final rolesList = userRolesString
        .split(',')
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();

    if (rolesList.contains('SUPER_ADMIN')) {
      return true;
    }

    for (final role in rolesList) {
      final perm = getPermissionForRole(role);
      if (predicate(perm)) {
        return true;
      }
    }

    return false;
  }

  Future<bool> updateRolePermissions(RolePermissionModel model) async {
    try {
      _isLoading = true;
      notifyListeners();

      final key = model.roleKey.toUpperCase();
      await _collection.doc(key).set(model.toJson(), SetOptions(merge: true));

      _permissionsByRole[key] = model;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating role permissions: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetRoleToDefaults(String roleKey) async {
    try {
      _isLoading = true;
      notifyListeners();

      final key = roleKey.trim().toUpperCase();
      final defaultModel = RolePermissionModel.defaultForRole(key);

      await _collection.doc(key).set(defaultModel.toJson());
      _permissionsByRole[key] = defaultModel;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resetting role permissions: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

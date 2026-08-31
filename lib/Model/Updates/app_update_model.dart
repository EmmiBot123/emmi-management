import 'package:cloud_firestore/cloud_firestore.dart';

class AppUpdateModel {
  final String id;
  final String title;
  final String description;
  final String targetApp; // 'all', 'emmi_lite', 'emmi_core', 'qubiq_studio', 'laser', etc.
  final String targetAppName; // Display name e.g. "Emmi Lite / Robot"
  final bool isCritical; // true for critical/mandatory updates
  final bool blockAppLaunch; // true if opening the app requires acknowledgement/update
  final String? versionTag; // e.g. "v2.4.0"
  final String? actionButtonText; // e.g. "Download Firmware"
  final String? actionUrl; // URL or documentation link
  final List<String> targetRoles; // ['all', 'student', 'teacher', 'admin']
  final List<String>? targetSchools; // Specific school codes or null for all
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? expiresAt;

  AppUpdateModel({
    required this.id,
    required this.title,
    required this.description,
    this.targetApp = 'all',
    this.targetAppName = 'All Applications',
    this.isCritical = false,
    this.blockAppLaunch = false,
    this.versionTag,
    this.actionButtonText,
    this.actionUrl,
    this.targetRoles = const ['all'],
    this.targetSchools,
    this.isActive = true,
    required this.createdAt,
    this.createdBy = 'Admin',
    this.expiresAt,
  });

  // Convert to JSON / Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetApp': targetApp,
      'targetAppName': targetAppName,
      'isCritical': isCritical,
      'blockAppLaunch': blockAppLaunch,
      'versionTag': versionTag,
      'actionButtonText': actionButtonText,
      'actionUrl': actionUrl,
      'targetRoles': targetRoles,
      'targetSchools': targetSchools,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  // Factory from Firestore Document
  factory AppUpdateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUpdateModel.fromMap(data, doc.id);
  }

  // Factory from Map
  factory AppUpdateModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return AppUpdateModel(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetApp: map['targetApp'] ?? 'all',
      targetAppName: map['targetAppName'] ?? _getDefaultAppName(map['targetApp'] ?? 'all'),
      isCritical: map['isCritical'] == true,
      blockAppLaunch: map['blockAppLaunch'] == true,
      versionTag: map['versionTag'] as String?,
      actionButtonText: map['actionButtonText'] as String?,
      actionUrl: map['actionUrl'] as String?,
      targetRoles: (map['targetRoles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['all'],
      targetSchools: (map['targetSchools'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      isActive: map['isActive'] ?? true,
      createdAt: parseDateTime(map['createdAt']),
      createdBy: map['createdBy'] ?? 'Admin',
      expiresAt: map['expiresAt'] != null ? parseDateTime(map['expiresAt']) : null,
    );
  }

  AppUpdateModel copyWith({
    String? id,
    String? title,
    String? description,
    String? targetApp,
    String? targetAppName,
    bool? isCritical,
    bool? blockAppLaunch,
    String? versionTag,
    String? actionButtonText,
    String? actionUrl,
    List<String>? targetRoles,
    List<String>? targetSchools,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
    DateTime? expiresAt,
  }) {
    return AppUpdateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetApp: targetApp ?? this.targetApp,
      targetAppName: targetAppName ?? this.targetAppName,
      isCritical: isCritical ?? this.isCritical,
      blockAppLaunch: blockAppLaunch ?? this.blockAppLaunch,
      versionTag: versionTag ?? this.versionTag,
      actionButtonText: actionButtonText ?? this.actionButtonText,
      actionUrl: actionUrl ?? this.actionUrl,
      targetRoles: targetRoles ?? this.targetRoles,
      targetSchools: targetSchools ?? this.targetSchools,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static String _getDefaultAppName(String appKey) {
    switch (appKey) {
      case 'all':
        return 'All Applications';
      case 'emmi_lite':
        return 'Emmi Lite (Robot Coding)';
      case 'emmi_core':
        return 'Emmi Core (Robot Manager)';
      case 'qubiq_studio':
        return 'QubiQ Studio (App Builder)';
      case 'laser':
        return 'LaserBurn (Laser Cutter)';
      case 'drone_block':
        return 'Drone Tuning';
      case 'antipython':
        return 'AntiPython IDE';
      case 'pyblock':
        return 'PyBlock';
      case 'cpp_compiler':
        return 'C++ Compiler';
      case 'c_compiler':
        return 'C Compiler';
      case 'html_learning':
        return 'HTML/CSS Lab';
      case 'paint':
        return 'Paint 3D';
      case 'keyboard_game':
        return 'Keyboard Game';
      case 'excel':
        return 'Excel AI Studio';
      case 'word':
        return 'Word AI Studio';
      case 'powerpoint':
        return 'PowerPoint AI';
      case 'ar_studio':
        return 'AR Studio';
      case 'typing':
        return 'Typing Master';
      case 'flowchart_ide':
        return 'Flowchart IDE';
      default:
        return appKey;
    }
  }

  static const List<Map<String, String>> supportedApps = [
    {'id': 'all', 'name': 'All Applications (Global)'},
    {'id': 'emmi_lite', 'name': 'Emmi Lite (Robot Coding)'},
    {'id': 'emmi_core', 'name': 'Emmi Core (Robot Manager)'},
    {'id': 'qubiq_studio', 'name': 'QubiQ Studio (App Builder)'},
    {'id': 'laser', 'name': 'LaserBurn (Laser Cutter)'},
    {'id': 'drone_block', 'name': 'Drone Tuning'},
    {'id': 'antipython', 'name': 'AntiPython IDE'},
    {'id': 'pyblock', 'name': 'PyBlock'},
    {'id': 'cpp_compiler', 'name': 'C++ Compiler'},
    {'id': 'c_compiler', 'name': 'C Compiler'},
    {'id': 'html_learning', 'name': 'HTML/CSS Lab'},
    {'id': 'paint', 'name': 'Paint 3D'},
    {'id': 'keyboard_game', 'name': 'Keyboard Game'},
    {'id': 'excel', 'name': 'Excel AI Studio'},
    {'id': 'word', 'name': 'Word AI Studio'},
    {'id': 'powerpoint', 'name': 'PowerPoint AI'},
    {'id': 'ar_studio', 'name': 'AR Studio'},
    {'id': 'typing', 'name': 'Typing Master'},
    {'id': 'flowchart_ide', 'name': 'Flowchart IDE'},
  ];
}

class RolePermissionModel {
  final String roleKey;
  final String roleTitle;

  // Screen / Navigation Access
  final bool canAccessDashboard;
  final bool canAccessInventory;
  final bool canAccessOperations;
  final bool canAccessSales;
  final bool canAccessAccounts;
  final bool canAccessUsers;
  final bool canAccessTesting;
  final bool canAccessContentHub;
  final bool canAccessDigitalMarketing;
  final bool canAccessTutorials;
  final bool canAccessQubiq;
  final bool canAccessDeployment;

  // Action Capabilities
  final bool canModifyInventory;
  final bool canDeleteInventory;
  final bool canEditProducts;
  final bool canManageBills;
  final bool canManageUsers;
  final bool canSignOffInstallation;
  final bool canExportReports;

  const RolePermissionModel({
    required this.roleKey,
    required this.roleTitle,
    this.canAccessDashboard = false,
    this.canAccessInventory = false,
    this.canAccessOperations = false,
    this.canAccessSales = false,
    this.canAccessAccounts = false,
    this.canAccessUsers = false,
    this.canAccessTesting = false,
    this.canAccessContentHub = false,
    this.canAccessDigitalMarketing = false,
    this.canAccessTutorials = false,
    this.canAccessQubiq = false,
    this.canAccessDeployment = false,
    this.canModifyInventory = false,
    this.canDeleteInventory = false,
    this.canEditProducts = false,
    this.canManageBills = false,
    this.canManageUsers = false,
    this.canSignOffInstallation = false,
    this.canExportReports = false,
  });

  bool canAccessRoleScreen(String roleScreenName) {
    switch (roleScreenName) {
      case 'Dashboard':
        return canAccessDashboard;
      case 'Inventory':
        return canAccessInventory;
      case 'Operations':
        return canAccessOperations;
      case 'Marketing':
      case 'Sales':
        return canAccessSales;
      case 'Accounts':
        return canAccessAccounts;
      case 'Users':
        return canAccessUsers;
      case 'Testing':
        return canAccessTesting;
      case 'Content Hub':
        return canAccessContentHub;
      case 'Digital Marketing':
        return canAccessDigitalMarketing;
      case 'Tutorials':
        return canAccessTutorials;
      case 'Qubiq':
      case 'QubiQ Manager':
      case 'App Broadcasts':
        return canAccessQubiq;
      case 'Deployment Dashboard':
        return canAccessDeployment;
      case 'CEO Dashboard':
        return roleKey == 'CEO' || roleKey == 'SUPER_ADMIN';
      case 'Assistant Dashboard':
        return roleKey == 'ASSISTANT' || roleKey == 'SUPER_ADMIN';
      default:
        return false;
    }
  }

  RolePermissionModel copyWith({
    String? roleKey,
    String? roleTitle,
    bool? canAccessDashboard,
    bool? canAccessInventory,
    bool? canAccessOperations,
    bool? canAccessSales,
    bool? canAccessAccounts,
    bool? canAccessUsers,
    bool? canAccessTesting,
    bool? canAccessContentHub,
    bool? canAccessDigitalMarketing,
    bool? canAccessTutorials,
    bool? canAccessQubiq,
    bool? canAccessDeployment,
    bool? canModifyInventory,
    bool? canDeleteInventory,
    bool? canEditProducts,
    bool? canManageBills,
    bool? canManageUsers,
    bool? canSignOffInstallation,
    bool? canExportReports,
  }) {
    return RolePermissionModel(
      roleKey: roleKey ?? this.roleKey,
      roleTitle: roleTitle ?? this.roleTitle,
      canAccessDashboard: canAccessDashboard ?? this.canAccessDashboard,
      canAccessInventory: canAccessInventory ?? this.canAccessInventory,
      canAccessOperations: canAccessOperations ?? this.canAccessOperations,
      canAccessSales: canAccessSales ?? this.canAccessSales,
      canAccessAccounts: canAccessAccounts ?? this.canAccessAccounts,
      canAccessUsers: canAccessUsers ?? this.canAccessUsers,
      canAccessTesting: canAccessTesting ?? this.canAccessTesting,
      canAccessContentHub: canAccessContentHub ?? this.canAccessContentHub,
      canAccessDigitalMarketing: canAccessDigitalMarketing ?? this.canAccessDigitalMarketing,
      canAccessTutorials: canAccessTutorials ?? this.canAccessTutorials,
      canAccessQubiq: canAccessQubiq ?? this.canAccessQubiq,
      canAccessDeployment: canAccessDeployment ?? this.canAccessDeployment,
      canModifyInventory: canModifyInventory ?? this.canModifyInventory,
      canDeleteInventory: canDeleteInventory ?? this.canDeleteInventory,
      canEditProducts: canEditProducts ?? this.canEditProducts,
      canManageBills: canManageBills ?? this.canManageBills,
      canManageUsers: canManageUsers ?? this.canManageUsers,
      canSignOffInstallation: canSignOffInstallation ?? this.canSignOffInstallation,
      canExportReports: canExportReports ?? this.canExportReports,
    );
  }

  factory RolePermissionModel.fromJson(Map<String, dynamic>? json, [String? docId]) {
    if (json == null) {
      return RolePermissionModel.defaultForRole(docId ?? 'USER');
    }

    final key = docId ?? json['roleKey']?.toString() ?? 'USER';
    final defaults = RolePermissionModel.defaultForRole(key);

    return RolePermissionModel(
      roleKey: key,
      roleTitle: json['roleTitle']?.toString() ?? defaults.roleTitle,
      canAccessDashboard: json['canAccessDashboard'] as bool? ?? defaults.canAccessDashboard,
      canAccessInventory: json['canAccessInventory'] as bool? ?? defaults.canAccessInventory,
      canAccessOperations: json['canAccessOperations'] as bool? ?? defaults.canAccessOperations,
      canAccessSales: json['canAccessSales'] as bool? ?? defaults.canAccessSales,
      canAccessAccounts: json['canAccessAccounts'] as bool? ?? defaults.canAccessAccounts,
      canAccessUsers: json['canAccessUsers'] as bool? ?? defaults.canAccessUsers,
      canAccessTesting: json['canAccessTesting'] as bool? ?? defaults.canAccessTesting,
      canAccessContentHub: json['canAccessContentHub'] as bool? ?? defaults.canAccessContentHub,
      canAccessDigitalMarketing: json['canAccessDigitalMarketing'] as bool? ?? defaults.canAccessDigitalMarketing,
      canAccessTutorials: json['canAccessTutorials'] as bool? ?? defaults.canAccessTutorials,
      canAccessQubiq: json['canAccessQubiq'] as bool? ?? defaults.canAccessQubiq,
      canAccessDeployment: json['canAccessDeployment'] as bool? ?? defaults.canAccessDeployment,
      canModifyInventory: json['canModifyInventory'] as bool? ?? defaults.canModifyInventory,
      canDeleteInventory: json['canDeleteInventory'] as bool? ?? defaults.canDeleteInventory,
      canEditProducts: json['canEditProducts'] as bool? ?? defaults.canEditProducts,
      canManageBills: json['canManageBills'] as bool? ?? defaults.canManageBills,
      canManageUsers: json['canManageUsers'] as bool? ?? defaults.canManageUsers,
      canSignOffInstallation: json['canSignOffInstallation'] as bool? ?? defaults.canSignOffInstallation,
      canExportReports: json['canExportReports'] as bool? ?? defaults.canExportReports,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleKey': roleKey,
      'roleTitle': roleTitle,
      'canAccessDashboard': canAccessDashboard,
      'canAccessInventory': canAccessInventory,
      'canAccessOperations': canAccessOperations,
      'canAccessSales': canAccessSales,
      'canAccessAccounts': canAccessAccounts,
      'canAccessUsers': canAccessUsers,
      'canAccessTesting': canAccessTesting,
      'canAccessContentHub': canAccessContentHub,
      'canAccessDigitalMarketing': canAccessDigitalMarketing,
      'canAccessTutorials': canAccessTutorials,
      'canAccessQubiq': canAccessQubiq,
      'canAccessDeployment': canAccessDeployment,
      'canModifyInventory': canModifyInventory,
      'canDeleteInventory': canDeleteInventory,
      'canEditProducts': canEditProducts,
      'canManageBills': canManageBills,
      'canManageUsers': canManageUsers,
      'canSignOffInstallation': canSignOffInstallation,
      'canExportReports': canExportReports,
    };
  }

  static RolePermissionModel defaultForRole(String roleKey) {
    final key = roleKey.trim().toUpperCase();

    if (key == 'SUPER_ADMIN') {
      return const RolePermissionModel(
        roleKey: 'SUPER_ADMIN',
        roleTitle: 'Super Administrator',
        canAccessDashboard: true,
        canAccessInventory: true,
        canAccessOperations: true,
        canAccessSales: true,
        canAccessAccounts: true,
        canAccessUsers: true,
        canAccessTesting: true,
        canAccessContentHub: true,
        canAccessDigitalMarketing: true,
        canAccessTutorials: true,
        canAccessQubiq: true,
        canAccessDeployment: true,
        canModifyInventory: true,
        canDeleteInventory: true,
        canEditProducts: true,
        canManageBills: true,
        canManageUsers: true,
        canSignOffInstallation: true,
        canExportReports: true,
      );
    }

    if (key == 'ADMIN') {
      return const RolePermissionModel(
        roleKey: 'ADMIN',
        roleTitle: 'Administrator',
        canAccessDashboard: true,
        canAccessInventory: true,
        canAccessOperations: true,
        canAccessSales: true,
        canAccessAccounts: true,
        canAccessUsers: true,
        canAccessTesting: true,
        canAccessContentHub: true,
        canAccessDigitalMarketing: true,
        canAccessTutorials: true,
        canAccessQubiq: true,
        canAccessDeployment: false,
        canModifyInventory: true,
        canDeleteInventory: true,
        canEditProducts: true,
        canManageBills: true,
        canManageUsers: true,
        canSignOffInstallation: true,
        canExportReports: true,
      );
    }

    if (key == 'ASSEMBLY_TEAM') {
      return const RolePermissionModel(
        roleKey: 'ASSEMBLY_TEAM',
        roleTitle: 'Assembly Team',
        canAccessOperations: true,
        canAccessInventory: true,
        canAccessTesting: true,
        canModifyInventory: true,
        canEditProducts: false,
      );
    }

    if (key == 'INSTALLATION_TEAM') {
      return const RolePermissionModel(
        roleKey: 'INSTALLATION_TEAM',
        roleTitle: 'Installation Team',
        canAccessOperations: true,
        canAccessInventory: true,
        canAccessTesting: true,
        canSignOffInstallation: true,
      );
    }

    if (key == 'ACCOUNTS') {
      return const RolePermissionModel(
        roleKey: 'ACCOUNTS',
        roleTitle: 'Accounts & Billing',
        canAccessAccounts: true,
        canAccessDashboard: false,
        canManageBills: true,
        canExportReports: true,
      );
    }

    if (key == 'MARKETING' || key == 'TELE_MARKETING') {
      return RolePermissionModel(
        roleKey: key,
        roleTitle: key == 'TELE_MARKETING' ? 'Tele-Marketing' : 'Field Marketing',
        canAccessSales: true,
        canAccessContentHub: true,
      );
    }

    if (key == 'DIGITAL_MARKETING') {
      return const RolePermissionModel(
        roleKey: 'DIGITAL_MARKETING',
        roleTitle: 'Digital Marketing & SEO',
        canAccessDigitalMarketing: true,
        canAccessContentHub: true,
      );
    }

    if (key == 'QUBIQ' || key == 'ADS') {
      return RolePermissionModel(
        roleKey: key,
        roleTitle: key == 'ADS' ? 'Ads & Media' : 'QubiQ Specialist',
        canAccessQubiq: true,
        canAccessSales: true,
        canAccessContentHub: true,
      );
    }

    if (key == 'TESTING') {
      return const RolePermissionModel(
        roleKey: 'TESTING',
        roleTitle: 'QA & Testing',
        canAccessTesting: true,
      );
    }

    if (key == 'DEPLOYMENT') {
      return const RolePermissionModel(
        roleKey: 'DEPLOYMENT',
        roleTitle: 'Deployment Staff',
        canAccessDeployment: true,
        canAccessOperations: true,
        canAccessContentHub: true,
        canAccessQubiq: true,
      );
    }

    if (key == 'TUTORIALS') {
      return const RolePermissionModel(
        roleKey: 'TUTORIALS',
        roleTitle: 'Tutorials & Training',
        canAccessTutorials: true,
        canAccessContentHub: true,
      );
    }

    // Default fallback
    return RolePermissionModel(
      roleKey: key,
      roleTitle: key,
    );
  }
}

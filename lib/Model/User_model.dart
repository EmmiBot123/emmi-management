class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final List<String>? roleId;
  final bool isEnabled;
  final String? createdTime;
  final String? createdById;
  final String? createdByName;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.roleId,
    bool? isEnabled,
    this.createdTime,
    this.createdById,
    this.createdByName,
  }) : isEnabled = isEnabled ?? false; // default value

  // Convert JSON → UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      roleId: json['roleId'] != null ? List<String>.from(json['roleId']) : null,
      isEnabled: json['enabled'] ?? json['isEnabled'], // nullable allowed
      createdTime: json['createdTime'],
      createdById: json['createdById'],
      createdByName: json['createdByName'],
    );
  }

  // Convert UserModel → JSON (for sending to backend if needed)
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "role": role,
      "roleId": roleId,
      "isEnabled": isEnabled,
      "createdTime": createdTime,
      "createdById": createdById,
      "createdByName": createdByName,
    };
  }
}

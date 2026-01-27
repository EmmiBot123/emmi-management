class SharedUserNote {
  String userId;
  String userName;
  String note;
  DateTime createdAt;
  DateTime updatedAt;

  SharedUserNote({
    required this.userId,
    required this.userName,
    required this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory SharedUserNote.fromJson(Map<String, dynamic> json) {
    return SharedUserNote(
      userId: json["userId"],
      userName: json["userName"],
      note: json["note"] ?? "",
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
      updatedAt: json["updatedAt"] != null
          ? DateTime.parse(json["updatedAt"])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "userName": userName,
      "note": note,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }
}

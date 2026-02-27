class TestingFeedback {
  final String? id;
  final String section;
  final String errorText;
  final String updateText;
  final DateTime createdAt;
  final String createdByUserId;
  final String createdByName;

  TestingFeedback({
    this.id,
    required this.section,
    required this.errorText,
    required this.updateText,
    required this.createdAt,
    required this.createdByUserId,
    required this.createdByName,
  });

  factory TestingFeedback.fromJson(Map<String, dynamic> json) {
    return TestingFeedback(
      id: json['id'],
      section: json['section'] ?? '',
      errorText: json['errorText'] ?? '',
      updateText: json['updateText'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      createdByUserId: json['createdByUserId'] ?? '',
      createdByName: json['createdByName'] ?? 'Unknown User',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section': section,
      'errorText': errorText,
      'updateText': updateText,
      'createdAt': createdAt.toIso8601String(),
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
    };
  }
}

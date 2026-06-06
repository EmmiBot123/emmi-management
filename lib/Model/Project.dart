import 'Course.dart';

class Project {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String status;
  final List<String> tags;
  final String imageUrl;
  final String githubUrl;
  final String liveUrl;
  final List<CustomSection> customSections;
  final DateTime? scheduledPublishDate;
  final DateTime? createdAt;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    this.status = 'Draft',
    this.tags = const [],
    this.imageUrl = '',
    this.githubUrl = '',
    this.liveUrl = '',
    this.customSections = const [],
    this.scheduledPublishDate,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'Beginner',
      status: json['status'] ?? 'Draft',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      imageUrl: json['imageUrl'] ?? '',
      githubUrl: json['githubUrl'] ?? '',
      liveUrl: json['liveUrl'] ?? '',
      customSections: json['customSections'] != null
          ? (json['customSections'] as List)
              .map((i) => CustomSection.fromJson(i))
              .toList()
          : [],
      scheduledPublishDate: json['scheduledPublishDate'] != null 
          ? DateTime.tryParse(json['scheduledPublishDate']) 
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'status': status,
      'tags': tags,
      'imageUrl': imageUrl,
      'githubUrl': githubUrl,
      'liveUrl': liveUrl,
      'customSections': customSections.map((i) => i.toJson()).toList(),
      if (scheduledPublishDate != null) 'scheduledPublishDate': scheduledPublishDate!.toIso8601String(),
    };
  }
}

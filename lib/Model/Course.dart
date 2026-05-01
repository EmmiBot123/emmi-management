class CurriculumItem {
  final String title;
  final String type; // e.g., "Video", "Assessment"
  final String duration;
  final String videoUrl;

  CurriculumItem({
    required this.title,
    required this.type,
    required this.duration,
    this.videoUrl = '',
  });

  factory CurriculumItem.fromJson(Map<String, dynamic> json) {
    return CurriculumItem(
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      duration: json['duration'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'duration': duration,
      'videoUrl': videoUrl,
    };
  }
}

class Course {
  final String id;
  final String name;
  final String description;
  final String category;
  final String duration;
  final double price;
  final String imageUrl;
  final String level; // Beginner, Intermediate, Advanced
  final String language;
  final List<String> learningPoints;
  final List<String> includedItems;
  final List<CurriculumItem> curriculum;
  final DateTime? createdAt;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.duration,
    required this.price,
    this.imageUrl = '',
    this.level = 'Beginner',
    this.language = 'English',
    this.learningPoints = const [],
    this.includedItems = const [],
    this.curriculum = const [],
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      duration: json['duration'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      level: json['level'] ?? 'Beginner',
      language: json['language'] ?? 'English',
      learningPoints: json['learningPoints'] != null
          ? List<String>.from(json['learningPoints'])
          : [],
      includedItems: json['includedItems'] != null
          ? List<String>.from(json['includedItems'])
          : [],
      curriculum: json['curriculum'] != null
          ? (json['curriculum'] as List)
              .map((i) => CurriculumItem.fromJson(i))
              .toList()
          : [],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'duration': duration,
      'price': price,
      'imageUrl': imageUrl,
      'level': level,
      'language': language,
      'learningPoints': learningPoints,
      'includedItems': includedItems,
      'curriculum': curriculum.map((i) => i.toJson()).toList(),
    };
  }
}

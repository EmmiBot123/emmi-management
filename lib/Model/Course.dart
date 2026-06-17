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

class CustomSection {
  final String title;
  final List<String> items;

  CustomSection({
    required this.title,
    required this.items,
  });

  factory CustomSection.fromJson(Map<String, dynamic> json) {
    return CustomSection(
      title: json['title'] ?? '',
      items: json['items'] != null ? List<String>.from(json['items']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': items,
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
  final double? offerPrice;
  final String imageUrl;
  final String level; // Beginner, Intermediate, Advanced
  final String language;
  final String status;
  final List<String> learningPoints;
  final List<String> includedItems;
  final List<CurriculumItem> curriculum;
  final List<CustomSection> customSections;
  final DateTime? scheduledPublishDate;
  final DateTime? createdAt;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.duration,
    required this.price,
    this.offerPrice,
    this.imageUrl = '',
    this.level = 'Beginner',
    this.language = 'English',
    this.status = 'Draft',
    this.learningPoints = const [],
    this.includedItems = const [],
    this.curriculum = const [],
    this.customSections = const [],
    this.scheduledPublishDate,
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
      offerPrice: json['offerPrice'] != null ? (json['offerPrice'] as num).toDouble() : null,
      imageUrl: json['imageUrl'] ?? '',
      level: json['level'] ?? 'Beginner',
      language: json['language'] ?? 'English',
      status: json['status'] ?? 'Draft',
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
      customSections: json['customSections'] != null
          ? (json['customSections'] as List)
              .map((i) => CustomSection.fromJson(i))
              .toList()
          : [],
      scheduledPublishDate: json['scheduledPublishDate'] != null 
          ? DateTime.tryParse(json['scheduledPublishDate']) 
          : null,
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
      if (offerPrice != null) 'offerPrice': offerPrice,
      'imageUrl': imageUrl,
      'level': level,
      'language': language,
      'status': status,
      'learningPoints': learningPoints,
      'includedItems': includedItems,
      'curriculum': curriculum.map((i) => i.toJson()).toList(),
      'customSections': customSections.map((i) => i.toJson()).toList(),
      if (scheduledPublishDate != null) 'scheduledPublishDate': scheduledPublishDate!.toIso8601String(),
    };
  }
}

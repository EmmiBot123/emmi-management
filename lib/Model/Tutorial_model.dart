import 'package:cloud_firestore/cloud_firestore.dart';

class TutorialModel {
  String? id;
  String title;
  String description;
  String category;
  String youtubeUrl;
  DateTime? createdAt;

  TutorialModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.youtubeUrl,
    this.createdAt,
  });

  factory TutorialModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return TutorialModel(
      id: docId ?? json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      youtubeUrl: json['youtubeUrl'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'youtubeUrl': youtubeUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  String? get videoId {
    try {
      final uri = Uri.parse(youtubeUrl);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.last;
      }
      return uri.queryParameters['v'];
    } catch (e) {
      return null;
    }
  }

  String get thumbnailUrl =>
      videoId != null ? "https://img.youtube.com/vi/$videoId/0.jpg" : "";
}

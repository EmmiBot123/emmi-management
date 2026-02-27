import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  String? id;
  String? title;
  String? youtubeUrl;
  DateTime? createdAt;

  AdModel({
    this.id,
    this.title,
    this.youtubeUrl,
    this.createdAt,
  });

  factory AdModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AdModel(
      id: docId ?? json['id'],
      title: json['title'],
      youtubeUrl: json['youtubeUrl'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'youtubeUrl': youtubeUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Helper to extract video ID for thumbnails
  String? get videoId {
    if (youtubeUrl == null) return null;
    try {
      final uri = Uri.parse(youtubeUrl!);
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

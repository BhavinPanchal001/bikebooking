import 'package:cloud_firestore/cloud_firestore.dart';

class CmsPageModel {
  const CmsPageModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.bodyMarkdown,
    required this.isPublished,
    required this.version,
    required this.publishedVersion,
    required this.publishedTitle,
    required this.publishedBodyMarkdown,
    this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String bodyMarkdown;
  final bool isPublished;
  final int version;
  final int publishedVersion;
  final String publishedTitle;
  final String publishedBodyMarkdown;
  final DateTime? publishedAt;

  String get effectiveTitle {
    final normalizedPublishedTitle = publishedTitle.trim();
    if (normalizedPublishedTitle.isNotEmpty) {
      return normalizedPublishedTitle;
    }

    return title.trim();
  }

  String get effectiveBodyMarkdown {
    final normalizedPublishedBody = publishedBodyMarkdown.trim();
    if (normalizedPublishedBody.isNotEmpty) {
      return normalizedPublishedBody;
    }

    return bodyMarkdown.trim();
  }

  factory CmsPageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CmsPageModel(
      id: documentId,
      slug: documentId.trim(),
      title: (data['title'] ?? '').toString().trim(),
      bodyMarkdown: (data['bodyMarkdown'] ?? '').toString().trim(),
      isPublished: data['isPublished'] == true,
      version: _toInt(data['version'], fallback: 1),
      publishedVersion: _toInt(data['publishedVersion']),
      publishedTitle: (data['publishedTitle'] ?? '').toString().trim(),
      publishedBodyMarkdown:
          (data['publishedBodyMarkdown'] ?? '').toString().trim(),
      publishedAt: _toDateTime(data['publishedAt']),
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '');
  }
}

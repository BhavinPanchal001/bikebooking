import 'package:bikebooking/features/home/data/models/cms_page_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CmsPageService {
  CmsPageService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>> get _pagesRef =>
      (_firestore ?? FirebaseFirestore.instance).collection('cms_pages');

  Stream<List<CmsPageModel>> watchAllPublishedPages() {
    return _pagesRef
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final pages = snapshot.docs
          .map((doc) => CmsPageModel.fromMap(doc.data(), doc.id))
          .where((page) => page.effectiveTitle.isNotEmpty)
          .toList();
      pages.sort((a, b) {
        final aTime = a.publishedAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.publishedAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return pages;
    });
  }

  Stream<CmsPageModel?> watchPublishedPage(String slug) {
    final normalizedSlug = slug.trim();
    if (normalizedSlug.isEmpty) {
      return Stream<CmsPageModel?>.value(null);
    }

    return _pagesRef.doc(normalizedSlug).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }

      final page = CmsPageModel.fromMap(data, snapshot.id);
      if (!page.isPublished || page.effectiveBodyMarkdown.isEmpty) {
        return null;
      }

      return page;
    });
  }
}

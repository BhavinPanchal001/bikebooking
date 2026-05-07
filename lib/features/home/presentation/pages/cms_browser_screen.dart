import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/home/data/models/cms_page_model.dart';
import 'package:bikebooking/features/home/data/services/cms_page_service.dart';
import 'package:bikebooking/features/home/presentation/pages/cms_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CmsBrowserScreen extends StatelessWidget {
  const CmsBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CmsPageService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<List<CmsPageModel>>(
                stream: service.watchAllPublishedPages(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load pages. Please try again later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  final pages = snapshot.data ?? [];

                  if (pages.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No pages available yet.',
                          style: TextStyle(
                            color: Color(0xFF5E6E8C),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: pages.length,
                    itemBuilder: (context, index) =>
                        _buildPageTile(context, pages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Information & legal pages',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTile(BuildContext context, CmsPageModel page) {
    final publishedAt = page.publishedAt;
    final subtitle = publishedAt != null
        ? 'Updated ${DateFormat('dd MMM yyyy').format(publishedAt)}'
        : 'Published';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CmsPageScreen(
            slug: page.slug,
            fallbackTitle: page.effectiveTitle,
            fallbackMarkdown: page.effectiveBodyMarkdown,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.article_outlined,
                color: Color(0xFF233A66),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.effectiveTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF233A66),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5E6E8C),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF5E6E8C),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

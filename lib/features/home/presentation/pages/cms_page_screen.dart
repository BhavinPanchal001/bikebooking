import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/home/data/models/cms_page_model.dart';
import 'package:bikebooking/features/home/data/services/cms_page_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CmsPageScreen extends StatelessWidget {
  const CmsPageScreen({
    super.key,
    required this.slug,
    required this.fallbackTitle,
    required this.fallbackMarkdown,
    this.cmsPageService,
  });

  final String slug;
  final String fallbackTitle;
  final String fallbackMarkdown;
  final CmsPageService? cmsPageService;

  @override
  Widget build(BuildContext context) {
    final pageService = cmsPageService ?? CmsPageService();

    return StreamBuilder<CmsPageModel?>(
      stream: pageService.watchPublishedPage(slug),
      builder: (context, snapshot) {
        final page = snapshot.data;
        final resolvedTitle = _resolveTitle(page);
        final resolvedMarkdown = _resolveMarkdown(page);

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBFF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, resolvedTitle),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSourceCard(context, snapshot, page),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: MarkdownBody(
                          data: resolvedMarkdown,
                          onTapLink: (_, href, __) => _openLink(href),
                          styleSheet: _buildMarkdownStyleSheet(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolveTitle(CmsPageModel? page) {
    final liveTitle = page?.effectiveTitle ?? '';
    if (liveTitle.isNotEmpty) {
      return liveTitle;
    }

    return fallbackTitle;
  }

  String _resolveMarkdown(CmsPageModel? page) {
    final liveMarkdown = page?.effectiveBodyMarkdown ?? '';
    if (liveMarkdown.isNotEmpty) {
      return liveMarkdown;
    }

    return fallbackMarkdown;
  }

  Widget _buildHeader(BuildContext context, String title) {
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(
    BuildContext context,
    AsyncSnapshot<CmsPageModel?> snapshot,
    CmsPageModel? page,
  ) {
    final hasLivePage = page != null;
    final publishedAt = page?.publishedAt;
    final isLoading = snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData;
    final description = hasLivePage
        ? publishedAt != null
            ? 'Live CMS content published on ${DateFormat('dd MMM yyyy, hh:mm a').format(publishedAt)}.'
            : 'Live CMS content is active for this page.'
        : 'Showing bundled copy until a published CMS page exists for "$slug".';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: hasLivePage
                      ? const Color(0xFFE5F3EA)
                      : const Color(0xFFFFF2E7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasLivePage
                      ? Icons.cloud_done_outlined
                      : Icons.description_outlined,
                  color: hasLivePage
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFDD6B20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasLivePage ? 'CMS content is live' : 'Using bundled content',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF233A66),
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5E6E8C),
              height: 1.5,
            ),
          ),
          if (snapshot.hasError) ...[
            const SizedBox(height: 12),
            Text(
              'There was a temporary issue loading the latest CMS content, so this screen is using the bundled copy.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade800,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;

    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: baseTextTheme.bodyMedium?.copyWith(
        color: const Color(0xFF5E6E8C),
        fontSize: 14,
        height: 1.6,
      ),
      h1: baseTextTheme.headlineSmall?.copyWith(
        color: const Color(0xFF2E3E5C),
        fontWeight: FontWeight.bold,
      ),
      h2: baseTextTheme.titleLarge?.copyWith(
        color: const Color(0xFF2E3E5C),
        fontWeight: FontWeight.bold,
      ),
      h3: baseTextTheme.titleMedium?.copyWith(
        color: const Color(0xFF2E3E5C),
        fontWeight: FontWeight.bold,
      ),
      listBullet: baseTextTheme.bodyMedium?.copyWith(
        color: const Color(0xFF2E3E5C),
      ),
      strong: const TextStyle(
        color: Color(0xFF2E3E5C),
        fontWeight: FontWeight.bold,
      ),
      blockquoteDecoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      blockquotePadding: const EdgeInsets.all(14),
      code: const TextStyle(
        fontFamily: 'monospace',
        color: Color(0xFF2E3E5C),
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _openLink(String? href) async {
    final url = Uri.tryParse(href ?? '');
    if (url == null) {
      return;
    }

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

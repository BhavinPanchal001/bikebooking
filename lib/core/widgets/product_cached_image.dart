import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

typedef ProductImageBuilder = Widget Function(BuildContext context);

class ProductCachedImage extends StatelessWidget {
  const ProductCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.placeholderBuilder,
    this.errorBuilder,
    this.fadeInDuration = const Duration(milliseconds: 150),
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final ProductImageBuilder? placeholderBuilder;
  final ProductImageBuilder? errorBuilder;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl.trim();
    if (normalizedUrl.isEmpty) {
      return _buildError(context);
    }

    return CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      fadeInDuration: fadeInDuration,
      placeholder: (context, _) => _buildPlaceholder(context),
      errorWidget: (context, _, __) => _buildError(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholderBuilder != null) {
      return placeholderBuilder!(context);
    }

    return _buildError(context);
  }

  Widget _buildError(BuildContext context) {
    if (errorBuilder != null) {
      return errorBuilder!(context);
    }

    return const Center(
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey,
      ),
    );
  }
}

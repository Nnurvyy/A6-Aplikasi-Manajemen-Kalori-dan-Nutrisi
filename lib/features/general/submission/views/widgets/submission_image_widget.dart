import 'dart:io';
import 'package:flutter/material.dart';

/// Widget untuk menampilkan gambar submission yang bisa berupa:
/// - URL Cloudinary (https://res.cloudinary.com/...) → sudah tersync ke cloud
/// - Path file lokal → sementara sebelum upload selesai
/// - String kosong → tampilkan placeholder
///
/// Gunakan widget ini di semua tempat yang menampilkan foto submission
/// (user card, admin card, detail screen, image viewer, dll).
class SubmissionImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? loadingWidget;

  const SubmissionImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.loadingWidget,
  });

  bool get _isNetworkUrl =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  bool get _isLocalFile =>
      imagePath.isNotEmpty && !_isNetworkUrl && !imagePath.startsWith('assets');

  bool get _isAsset => imagePath.startsWith('assets');

  Widget _defaultPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFFE8F5E9),
          child: const Center(
            child: Icon(
              Icons.fastfood_rounded,
              color: Color(0xFF2ECC71),
              size: 40,
            ),
          ),
        );
  }

  Widget _defaultLoading() {
    return loadingWidget ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFFE8F5E9),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2ECC71),
              ),
            ),
          ),
        );
  }

  Widget _buildImageWidget() {
    if (imagePath.isEmpty) return _defaultPlaceholder();

    Widget image;

    if (_isNetworkUrl) {
      // URL dari Cloudinary — tampilkan via Image.network
      image = Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _defaultPlaceholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _defaultLoading();
        },
      );
    } else if (_isLocalFile && File(imagePath).existsSync()) {
      // File lokal — belum tersync, tampilkan sementara
      image = Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _defaultPlaceholder(),
      );
    } else if (_isAsset) {
      image = Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _defaultPlaceholder(),
      );
    } else {
      return _defaultPlaceholder();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  @override
  Widget build(BuildContext context) => _buildImageWidget();
}

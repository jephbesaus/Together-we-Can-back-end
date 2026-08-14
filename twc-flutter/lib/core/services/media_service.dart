import '../../app/constants.dart';

/// Résout une URL de média potentiellement relative (/storage/...) en URL
/// absolue utilisable par CachedNetworkImage / Image.network.
class MediaService {
  MediaService._();

  /// Retourne l'origine du backend (sans le suffixe /api).
  static String get origin {
    final base = AppConstants.apiBaseUrl;
    return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  }

  static String? resolveUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    if (url.startsWith('//')) {
      return 'https:' + url;
    }

    final base = origin;
    if (url.startsWith('/')) {
      return '$base$url';
    }

    // Chemin relatif sans slash initial (ex: posts/2024/xx.jpg)
    return '$base/storage/${url.replaceFirst(RegExp(r'^storage/'), '')}';
  }
}

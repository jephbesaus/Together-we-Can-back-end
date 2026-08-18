import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  Uri? _initialLink;

  void init() {
    _handleInitialLink();
    _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (err) {});
  }

  Future<void> _handleInitialLink() async {
    try {
      _initialLink = await _appLinks.getInitialLink();
      if (_initialLink != null) {
        _handleUri(_initialLink!);
      }
    } catch (_) {}
  }

  void _handleUri(Uri uri) {
    if (uri.scheme != 'twc') return;

    if (uri.host == 'payment') {
      final type = uri.queryParameters['type'] ?? 'deposit';
      final courseId = uri.queryParameters['courseId'];

      if (type == 'course' && courseId != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.toNamed('/course-detail', arguments: {'courseId': int.tryParse(courseId)});
        });
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.toNamed('/wallet');
        });
      }
    }

    if (uri.host == 'register') {
      final ref = uri.queryParameters['ref'];
      if (ref != null && ref.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.toNamed('/register', arguments: {'referral_code': ref});
        });
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  void init() {
    _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (err) {});
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'twc' && uri.host == 'payment') {
      final courseId = uri.queryParameters['courseId'];
      if (courseId != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.toNamed('/course-detail', arguments: {'courseId': int.tryParse(courseId)});
        });
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

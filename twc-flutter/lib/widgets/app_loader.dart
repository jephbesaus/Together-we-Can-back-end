import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/constants.dart';

/// Loader de marque : utilisé pour l'écran de démarrage et les chargements
/// à plein écran (soumissions de formulaires, etc.).
class AppLoader extends StatefulWidget {
  final String? message;
  final bool centered;

  const AppLoader({super.key, this.message, this.centered = true});

  /// Affiche une surcouche plein écran bloquante (à base de Get.dialog).
  static void show({String? message}) {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      PopScope(
        canPop: false,
        child: AppLoader(message: message),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black45,
    );
  }

  static void hide() {
    if (Get.isDialogOpen == true) Get.back();
  }

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * 3.141592653589793,
                    child: child,
                  );
                },
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.primaryColor.withValues(alpha: 0.15),
                      width: 6,
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_controller.value * 2 * 3.141592653589793,
                    child: child,
                  );
                },
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.primaryColor.withValues(alpha: 0.35),
                      width: 5,
                    ),
                  ),
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'TW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (widget.message != null) ...[
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          AppConstants.appName,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
          ),
        ),
      ],
    );

    if (!widget.centered) {
      return content;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}

/// État de chargement utilisé dans les écrans (en remplacement du simple
/// CircularProgressIndicator) pour une expérience plus "pro".
class AppLoadingView extends StatelessWidget {
  final String? message;

  const AppLoadingView({super.key, this.message = 'Chargement...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLoader(centered: false),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

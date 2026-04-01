import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/app_colors.dart';

/// Data class for completion messages with success/error state.
class AiCompletionData {
  const AiCompletionData({
    required this.message,
    this.isSuccess = true,
  });
  final String message;
  final bool isSuccess;
}

/// Provider to show/hide the AI completion notification.
final aiCompletionMessageProvider =
    StateProvider<AiCompletionData?>((ref) => null);

/// Provider to store completion messages so they appear in chat history.
final aiCompletionHistoryProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Overlay widget that shows AI completion messages as a centered popup.
/// Shows 🎉 for success, ⚠️ for errors.
class AiCompletionOverlay extends ConsumerStatefulWidget {
  const AiCompletionOverlay({super.key});

  @override
  ConsumerState<AiCompletionOverlay> createState() =>
      _AiCompletionOverlayState();
}

class _AiCompletionOverlayState extends ConsumerState<AiCompletionOverlay>
    with TickerProviderStateMixin {
  Timer? _dismissTimer;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _visible = false;
  String _currentMessage = '';
  bool _isSuccess = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _show(AiCompletionData data) {
    _dismissTimer?.cancel();

    // Save to history so it can appear in chat
    final history = ref.read(aiCompletionHistoryProvider.notifier);
    history.state = [
      ...history.state,
      {
        'message': data.message,
        'isSuccess': data.isSuccess,
        'timestamp': DateTime.now(),
      },
    ];

    setState(() {
      _currentMessage = data.message;
      _isSuccess = data.isSuccess;
      _visible = true;
    });
    _animController.forward(from: 0);
    _dismissTimer = Timer(const Duration(seconds: 6), _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() => _visible = false);
        ref.read(aiCompletionMessageProvider.notifier).state = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiCompletionData?>(aiCompletionMessageProvider, (prev, next) {
      if (next != null && next.message.isNotEmpty) {
        _show(next);
      }
    });

    if (!_visible) return const SizedBox.shrink();

    final emoji = _isSuccess ? '🎉' : '⚠️';
    final title = _isSuccess ? 'تمت العملية بنجاح!' : 'ما قدرت أكمل العملية';
    final subtitle = _isSuccess
        ? 'أي شيء تبيه قولي بس وأبشر بسعدك 💙'
        : 'جرب مرة ثانية أو تواصل مع الدعم';
    final buttonText = _isSuccess ? 'تمام 👍' : 'حسناً';
    final shadowColor = _isSuccess
        ? AppColors.primary.withValues(alpha: 0.25)
        : AppColors.error.withValues(alpha: 0.2);

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
        onTap: _dismiss,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 40,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isSuccess ? AppColors.primary : AppColors.error,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

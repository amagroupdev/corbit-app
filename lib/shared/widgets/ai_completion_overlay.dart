import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/app_colors.dart';

/// Provider to show/hide the AI completion notification.
/// Set to a message string to show, null to hide.
final aiCompletionMessageProvider = StateProvider<String?>((ref) => null);

/// Provider to store completion messages so they appear in chat history.
/// Each entry is a map with 'message' and 'timestamp'.
final aiCompletionHistoryProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Overlay widget that shows AI completion messages as a centered popup dialog
/// with celebration animation (🎉).
/// Place this in the main shell Stack.
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
  late AnimationController _confettiController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _confettiFade;
  bool _visible = false;
  String _currentMessage = '';

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

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confettiFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _confettiController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _show(String message) {
    _dismissTimer?.cancel();

    // Save to history so it can appear in chat
    final history = ref.read(aiCompletionHistoryProvider.notifier);
    history.state = [
      ...history.state,
      {
        'message': message,
        'timestamp': DateTime.now(),
      },
    ];

    setState(() {
      _currentMessage = message;
      _visible = true;
    });
    _animController.forward(from: 0);
    _confettiController.forward(from: 0);
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
    ref.listen<String?>(aiCompletionMessageProvider, (prev, next) {
      if (next != null && next.isNotEmpty) {
        _show(next);
      }
    });

    if (!_visible) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: _dismiss,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {}, // prevent dismissing when tapping the card
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
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Confetti emoji
                      FadeTransition(
                        opacity: _confettiFade,
                        child: const Text(
                          '🎉',
                          style: TextStyle(fontSize: 56),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Success title
                      const Text(
                        'تمت العملية بنجاح!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Message
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

                      // Subtitle
                      const Text(
                        'أي شيء تبيه قولي بس وأبشر بسعدك 💙',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dismiss button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'تمام 👍',
                            style: TextStyle(
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
    );
  }
}

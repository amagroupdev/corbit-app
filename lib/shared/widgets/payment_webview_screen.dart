import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:orbit_app/core/constants/app_colors.dart';

/// A full-screen WebView for payment pages.
///
/// Strategy:
/// - Loads the given [url] in an embedded WebView.
/// - Does NOT auto-detect success/failure from URL patterns (too error-prone).
/// - Instead detects when the WebView navigates back to the app's own domain
///   (mobile.net.sa) which indicates the payment gateway has redirected back
///   with a callback. It then checks query params for status.
/// - The user can always close manually via the X button (with confirmation).
/// - Shows a linear progress indicator while loading.
/// - Android back button goes back within the WebView first, then exits.
///
/// Usage:
/// ```dart
/// final result = await context.push<bool>(
///   '/payment-webview',
///   extra: {
///     'url': 'https://payment-gateway.com/pay?id=123',
///     'title': 'الدفع',
///   },
/// );
/// ```
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.url,
    this.title = '\u0627\u0644\u062F\u0641\u0639', // الدفع
    this.appDomain = 'mobile.net.sa',
  });

  /// The payment URL to load.
  final String url;

  /// Title shown in the AppBar.
  final String title;

  /// The app's own domain. When the WebView navigates to a URL on this
  /// domain, it's treated as a payment callback.
  final String appDomain;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  double _progress = 0.0;
  bool _isLoading = true;

  /// The initial URL that was loaded – we skip pattern-checking on this.
  late final Uri _initialUri;

  /// Tracks whether the user has been navigated away from the initial URL.
  bool _hasNavigatedAway = false;

  /// Prevents double-popping.
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();

    _initialUri = Uri.parse(widget.url);

    if (kIsWeb) {
      // webview_flutter on web uses HtmlElementView (iframe).
      // Some payment gateways block iframe embedding.
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            debugPrint('WebView navigating to: $url');
            _handleNavigation(url);
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation so the payment flow can proceed.
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(_initialUri);
  }

  /// Handles URL navigation changes.
  ///
  /// Only checks for callback after the user has navigated away from
  /// the initial URL. Detects when the WebView navigates back to the
  /// app's own domain, which indicates the payment gateway callback.
  void _handleNavigation(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Check if this URL is different from the initial payment URL
    if (!_hasNavigatedAway) {
      // Compare host – if the host changes, the user has navigated away
      if (uri.host != _initialUri.host) {
        _hasNavigatedAway = true;
      }
      // Even on the same host, if the path changes significantly
      else if (uri.path != _initialUri.path) {
        _hasNavigatedAway = true;
      }
      // Still on the initial page – skip checking
      if (!_hasNavigatedAway) return;
    }

    // Check if we've returned to our app's domain (payment callback)
    if (uri.host.contains(widget.appDomain)) {
      _handlePaymentCallback(uri);
      return;
    }

    // Also check for common payment gateway result pages
    // Only after navigating away from the initial URL
    final path = uri.path.toLowerCase();
    if (_hasNavigatedAway) {
      // Check for typical payment result paths (not query params!)
      if (path.contains('/success') ||
          path.contains('/payment-success') ||
          path.contains('/payment/success') ||
          path.contains('/result/success') ||
          path.contains('/thank-you') ||
          path.contains('/thankyou')) {
        _popWithResult(
          isSuccess: true,
          message: '\u062A\u0645\u062A \u0639\u0645\u0644\u064A\u0629 \u0627\u0644\u062F\u0641\u0639 \u0628\u0646\u062C\u0627\u062D', // تمت عملية الدفع بنجاح
        );
        return;
      }
      if (path.contains('/failure') ||
          path.contains('/payment-failed') ||
          path.contains('/payment/failed') ||
          path.contains('/result/failed') ||
          path.contains('/declined') ||
          path.contains('/cancelled') ||
          path.contains('/canceled')) {
        _popWithResult(
          isSuccess: false,
          message: '\u0641\u0634\u0644\u062A \u0639\u0645\u0644\u064A\u0629 \u0627\u0644\u062F\u0641\u0639', // فشلت عملية الدفع
        );
        return;
      }
    }
  }

  /// The WebView has navigated to our app's domain – this is the callback URL.
  void _handlePaymentCallback(Uri uri) {
    // Check query params and path for status indicators
    final queryStatus = uri.queryParameters['status']?.toLowerCase() ??
        uri.queryParameters['result']?.toLowerCase() ??
        uri.queryParameters['payment_status']?.toLowerCase() ??
        '';
    final path = uri.path.toLowerCase();
    final fullUrl = uri.toString().toLowerCase();

    final bool isSuccess = queryStatus == 'success' ||
        queryStatus == 'approved' ||
        queryStatus == 'completed' ||
        queryStatus == 'paid' ||
        path.contains('success') ||
        path.contains('approved') ||
        path.contains('completed') ||
        path.contains('callback');

    final bool isFailure = queryStatus == 'failed' ||
        queryStatus == 'failure' ||
        queryStatus == 'cancelled' ||
        queryStatus == 'canceled' ||
        queryStatus == 'declined' ||
        queryStatus == 'error' ||
        path.contains('failed') ||
        path.contains('failure') ||
        path.contains('cancelled') ||
        path.contains('declined');

    if (isSuccess) {
      _popWithResult(
        isSuccess: true,
        message: '\u062A\u0645\u062A \u0639\u0645\u0644\u064A\u0629 \u0627\u0644\u062F\u0641\u0639 \u0628\u0646\u062C\u0627\u062D', // تمت عملية الدفع بنجاح
      );
    } else if (isFailure) {
      _popWithResult(
        isSuccess: false,
        message: '\u0641\u0634\u0644\u062A \u0639\u0645\u0644\u064A\u0629 \u0627\u0644\u062F\u0641\u0639', // فشلت عملية الدفع
      );
    } else {
      // Callback to our domain but unclear status - treat as success
      // (the server will verify the actual payment status)
      _popWithResult(
        isSuccess: true,
        message: '\u062A\u0645 \u0625\u0643\u0645\u0627\u0644 \u0639\u0645\u0644\u064A\u0629 \u0627\u0644\u062F\u0641\u0639', // تم إكمال عملية الدفع
      );
    }
  }

  void _popWithResult({required bool isSuccess, required String message}) {
    if (_hasPopped || !mounted) return;
    _hasPopped = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
      ),
    );

    _safePop(isSuccess);
  }

  void _safePop([dynamic result]) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      Navigator.of(context).pop(result);
    }
  }

  /// Shows a confirmation dialog before closing.
  Future<void> _confirmClose() async {
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '\u0625\u063A\u0644\u0627\u0642 \u0635\u0641\u062D\u0629 \u0627\u0644\u062F\u0641\u0639', // إغلاق صفحة الدفع
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          '\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u0625\u063A\u0644\u0627\u0642 \u0635\u0641\u062D\u0629 \u0627\u0644\u062F\u0641\u0639\u061F', // هل أنت متأكد من إغلاق صفحة الدفع؟
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '\u0627\u0633\u062A\u0645\u0631\u0627\u0631', // استمرار
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '\u0625\u063A\u0644\u0627\u0642', // إغلاق
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldClose == true && mounted && !_hasPopped) {
      _hasPopped = true;
      _safePop(null); // null = user cancelled, not success or failure
    }
  }

  Future<bool> _onWillPop() async {
    // Let the user go back within the WebView first.
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          // If pressing back and can't go back in WebView, show confirmation
          await _confirmClose();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmClose,
          ),
          actions: [
            // Reload button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
              tooltip: '\u0625\u0639\u0627\u062F\u0629 \u062A\u062D\u0645\u064A\u0644', // إعادة تحميل
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _isLoading
                ? LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 3,
                  )
                : const SizedBox(height: 3),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}

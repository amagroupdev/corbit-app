import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// A screen that displays a bundled PDF asset.
///
/// On **mobile** (Android/iOS), the PDF is copied from Flutter assets to
/// a temporary directory and displayed inline using WebView (which renders
/// PDFs natively). A "فتح خارجياً" button is available to open the PDF
/// in the system's default viewer via [OpenFilex].
///
/// On **web**, the PDF asset is served as a web resource and opened in a
/// new browser tab via [url_launcher].
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.assetPath,
    this.title = 'PDF',
  });

  /// Flutter asset path, e.g. `assets/pdf/terms_of_use_corbit.pdf`.
  final String assetPath;

  /// Title shown in the AppBar.
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  WebViewController? _webController;
  bool _isLoading = true;
  String? _error;
  String? _tempFilePath;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // On web, just open the asset in a new tab and pop back.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openOnWeb();
      });
    } else {
      _loadPdfForMobile();
    }
  }

  /// Web: open the asset URL in a new browser tab.
  Future<void> _openOnWeb() async {
    // On Flutter web, assets are accessible at a predictable path.
    final assetUrl = Uri.parse(widget.assetPath);
    try {
      await launchUrl(assetUrl, mode: LaunchMode.platformDefault);
    } catch (_) {
      // Fallback: try launching with full URL.
      try {
        await launchUrl(
          Uri.parse('${Uri.base.origin}/${widget.assetPath}'),
          mode: LaunchMode.platformDefault,
        );
      } catch (_) {}
    }

    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  /// Mobile: copy asset to temp and load in WebView.
  Future<void> _loadPdfForMobile() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final dir = await getTemporaryDirectory();
      final fileName = widget.assetPath.split('/').last;
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes.buffer.asUint8List());

      _tempFilePath = file.path;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              debugPrint('WebView PDF error: ${error.description}');
              // If WebView can't render the PDF, fallback to open_filex.
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _error = AppLocalizations.instance.translate('fileDisplayError');
                });
              }
            },
          ),
        )
        ..loadFile(file.path);

      if (mounted) {
        setState(() {
          _webController = controller;
        });
      }
    } catch (e) {
      debugPrint('PDF load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = AppLocalizations.instance.translate('fileLoadError');
        });
      }
    }
  }

  /// Open the file with the system's default PDF viewer.
  Future<void> _openExternally() async {
    if (_tempFilePath != null) {
      await OpenFilex.open(_tempFilePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // On web, we just show a brief loading state before popping.
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.instance.translate('openingFile'),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_tempFilePath != null)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: _openExternally,
              tooltip: AppLocalizations.instance.translate('openExternally'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            if (_tempFilePath != null)
              ElevatedButton.icon(
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(
                  AppLocalizations.instance.translate('openWithExternalApp'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (_webController != null) {
      return WebViewWidget(controller: _webController!);
    }

    return const SizedBox.shrink();
  }
}

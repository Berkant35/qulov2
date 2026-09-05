import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LegalWebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const LegalWebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final host = Uri.parse(widget.url).host;
    // Sayfa yüklendikten sonra web navbar'ını gizle (mobile'da gereksiz)
    const hideNavbarJs = '''
      (function() {
        var nav = document.querySelector('nav') || document.querySelector('header');
        if (nav) nav.style.display = 'none';
      })();
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() {
          _isLoading = true;
          _hasError = false;
        }),
        onPageFinished: (_) {
          setState(() => _isLoading = false);
          _controller.runJavaScript(hideNavbarJs);
        },
        onWebResourceError: (_) => setState(() {
          _isLoading = false;
          _hasError = true;
        }),
        onNavigationRequest: (request) {
          final requestHost = Uri.tryParse(request.url)?.host ?? '';
          if (requestHost == host || requestHost.endsWith('.$host')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  void _retry() {
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      padding: EdgeInsets.zero,
      showBackground: false,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: AppLoadingWidget()),
          if (_hasError && !_isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: context.appColors.error),
                  const SizedBox(height: 16),
                  Text(context.tr('error_generic')),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _retry,
                    child: Text(context.tr('retry')),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

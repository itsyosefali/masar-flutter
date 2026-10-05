import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/design.dart';

class PaymentFrame extends StatefulWidget {
  const PaymentFrame({super.key, required this.url, required this.onClose});
  final String url;
  final VoidCallback onClose;
  @override
  State<PaymentFrame> createState() => _PaymentFrameState();
}

class _PaymentFrameState extends State<PaymentFrame> {
  late final WebViewController controller;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = Uri.tryParse(request.url);
            final sameOrigin =
                url != null &&
                ['http', 'https'].contains(url.scheme) &&
                url.origin == Uri.parse(widget.url).origin;
            if (sameOrigin ||
                (!request.isMainFrame &&
                    url?.scheme == 'https' &&
                    [
                      'tnpg.moamalat.net',
                      'npg.moamalat.net',
                    ].contains(url?.host))) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => failed = true);
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'MasarPayment',
        onMessageReceived: (message) {
          // This only closes the view; the order is always reloaded from the backend.
          if (message.message == '{"type":"masar-payment-closed"}') {
            widget.onClose();
          }
        },
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) => failed
      ? Center(
          child: TextButton(
            onPressed: () {
              setState(() => failed = false);
              controller.loadRequest(Uri.parse(widget.url));
            },
            child: Text(
              context.tr(
                'Could not load payment. Retry',
                'تعذّر تحميل الدفع. أعد المحاولة',
              ),
            ),
          ),
        )
      : WebViewWidget(controller: controller);
}

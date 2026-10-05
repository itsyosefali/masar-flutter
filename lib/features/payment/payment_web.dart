import 'dart:js_interop';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class PaymentFrame extends StatefulWidget {
  const PaymentFrame({super.key, required this.url, required this.onClose});
  final String url;
  final VoidCallback onClose;
  @override
  State<PaymentFrame> createState() => _PaymentFrameState();
}

class _PaymentFrameState extends State<PaymentFrame> {
  web.HTMLIFrameElement? frame;
  late final JSFunction listener;
  @override
  void initState() {
    super.initState();
    listener = ((web.MessageEvent event) {
      if (event.origin != Uri.parse(widget.url).origin ||
          event.source != frame?.contentWindow) {
        return;
      }
      try {
        final data = jsonDecode((event.data as JSString).toDart);
        if (data['type'] == 'masar-payment-closed') widget.onClose();
      } catch (_) {}
    }).toJS;
    web.window.addEventListener('message', listener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      frame = element as web.HTMLIFrameElement;
      frame!
        ..src = widget.url
        ..title = 'Moamalat card payment'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
    },
  );
}

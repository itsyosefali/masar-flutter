import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/design.dart';
import 'payment_native.dart' if (dart.library.js_interop) 'payment_web.dart';

Future<void> showCardPayment(
  BuildContext context,
  CustomerApi api,
  OrderAccess access,
) async {
  try {
    final url = Uri.parse(await api.paymentUrl(access));
    if (!context.mounted) return;
    final localized = url.replace(
      queryParameters: {'lang': context.isArabic ? 'ar' : 'en'},
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              context.tr('Local card payment', 'الدفع بالبطاقة المحلية'),
            ),
          ),
          body: PaymentFrame(
            url: localized.toString(),
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.tr('Your order is saved', 'تم حفظ طلبك')),
        content: Text(errorText(c, error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(c.tr('Return to order', 'العودة إلى الطلب')),
          ),
        ],
      ),
    );
  }
}

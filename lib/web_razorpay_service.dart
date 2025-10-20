// lib/web_razorpay_service.dart
import 'dart:js' as js;

class RazorpayWeb {
  static void openCheckout({
    required String key,
    required double amount,
    required String name,
    required String description,
    required String contact,
    required String email,
  }) {
    // Define the checkout options
    final options = js.JsObject.jsify({
      'key': key,
      'amount': (amount * 100).toInt(), // convert to paise
      'name': name,
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'theme': {'color': '#10B981'},
      'handler': js.allowInterop((response) {
        js.context.callMethod('alert', [
          '✅ Payment Successful! Payment ID: ${response["razorpay_payment_id"]}'
        ]);
      }),
      'modal': {
        'ondismiss': js.allowInterop(() {
          js.context.callMethod('alert', ['❌ Payment cancelled by user']);
        })
      }
    });

    // Create Razorpay instance and open checkout
    final razorpay = js.JsObject(js.context['Razorpay'], [options]);
    razorpay.callMethod('open');
  }
}

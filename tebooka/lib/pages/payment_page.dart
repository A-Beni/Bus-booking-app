import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final double amount;
  final String passengerName;
  final String ticketId;

  const PaymentPage({
    super.key,
    required this.amount,
    required this.passengerName,
    required this.ticketId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = 'pk_test_51NxbKXSHs8Yxxxxxxx'; // Replace with your Stripe test publishable key
  }

  Future<void> _makePayment() async {
    setState(() => isLoading = true);

    try {
      // Simulate a call to backend that creates a PaymentIntent
      final response = await http.post(
        Uri.parse('https://your-backend-url.com/create-payment-intent'), // Replace with your backend
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': (widget.amount * 100).toInt()}), // Stripe requires cents
      );

      final paymentIntent = jsonDecode(response.body);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          merchantDisplayName: 'SmartBus',
          style: ThemeMode.light,
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'RW',
            testEnv: true,
          ),
          billingDetails: BillingDetails(
            name: widget.passengerName,
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Payment successful')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Payment failed: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F2FB),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blue,
        elevation: 4,
        centerTitle: true,
      ),
      body: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card, size: 50, color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text(
                'Pay RWF ${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Use a card to complete your payment.'),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _makePayment,
                icon: const Icon(Icons.lock),
                label: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Proceed to Pay'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

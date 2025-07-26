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
    // Set your Stripe publishable key here
    Stripe.publishableKey = 'pk_test_51RlavgQM4owSDyFaFTg1geGG73yRGcIiiDsqqh2C3SGDxIrGinP7pSkVw0Xn9mxCSC7TUgu2hUYpZtk6z3v9TtZ000yaYv3vK4';
    Stripe.instance.applySettings();
  }

  Future<void> _makePayment() async {
    setState(() => isLoading = true);

    try {
      // 1. Call Firebase Function to create PaymentIntent
      final response = await http.post(
        Uri.parse('https://us-central1-tebooka.cloudfunctions.net/createPaymentIntent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': (widget.amount * 100).toInt()}), // Amount in cents
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent');
      }

      final paymentIntent = jsonDecode(response.body);

      // 2. Initialize Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          merchantDisplayName: 'TEBOOKA',
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

      // 3. Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Payment successful')),
      );

      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Payment cancelled by user')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Payment failed: ${e.toString()}')),
        );
      }
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
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
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

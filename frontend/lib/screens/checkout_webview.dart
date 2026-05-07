import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class PayFastCheckoutScreen extends StatefulWidget {
  final String plan;
  const PayFastCheckoutScreen({super.key, required this.plan});

  @override
  State<PayFastCheckoutScreen> createState() => _PayFastCheckoutScreenState();
}

class _PayFastCheckoutScreenState extends State<PayFastCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _checkoutUrl;

  @override
  void initState() {
    super.initState();
    _loadCheckoutUrl();
  }

  Future<void> _loadCheckoutUrl() async {
    try {
      final authService = AuthService();
      final response = await authService.initiatePayment(widget.plan);
      
      setState(() {
        _checkoutUrl = response['checkout_url'];
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) => setState(() => _isLoading = true),
              onPageFinished: (url) => setState(() => _isLoading = false),
              onNavigationRequest: (request) {
                // Check if URL is success or cancel (based on PayFast setup)
                if (request.url.contains('success')) {
                  _handlePaymentSuccess();
                  return NavigationDecision.prevent;
                }
                if (request.url.contains('cancel')) {
                  Navigator.pop(context);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(_checkoutUrl!));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to initiate payment: $e")),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handlePaymentSuccess() async {
    // In a real app, the backend handles this via Webhook.
    // For dev testing, we'll call a "simulate success" endpoint to update the UI instantly.
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.simulatePaymentSuccess(); // I'll add this to AuthProvider
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 64),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Payment Successful!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("Your 10 Daily Pass credits have been added to your account.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close WebView
              Navigator.pop(context); // Close Pricing
            },
            child: const Text("Start Try-On", style: TextStyle(color: Color(0xFF7C5CFF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Checkout"),
        backgroundColor: const Color(0xFF0B1020),
      ),
      body: _checkoutUrl == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFF)))
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFF))),
              ],
            ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class IAPProvider extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Product IDs (Must match Google Play Console)
  static const String dailyPassId = 'daily_pass';

  IAPProvider() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print("IAP Stream Error: $error"),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      await fetchProducts();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    const Set<String> ids = {dailyPassId};
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);

    if (response.error != null) {
      _errorMessage = response.error!.message;
    } else {
      _products = response.productDetails;
    }
    notifyListeners();
  }

  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = "Failed to start purchase: $e";
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Show pending UI if needed
      } else if (purchase.status == PurchaseStatus.error) {
        _errorMessage = purchase.error?.message ?? "Purchase failed";
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        // Verify with backend
        final bool success = await _verifyPurchase(purchase);
        if (success) {
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      final authService = AuthService();
      // Call backend to verify token
      final User? updatedUser = await authService.verifyGooglePurchase(
        purchase.productID,
        purchase.verificationData.serverVerificationData,
      );
      
      if (updatedUser != null) {
        // Update local user state via AuthProvider (handled externally or via shared service)
        return true;
      }
      return false;
    } catch (e) {
      print("Verification Error: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

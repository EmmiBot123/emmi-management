import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Model/Marketing/ProductRequest.dart';
import '../../Model/productDetails/ProductComponent.dart';
import '../../Model/productDetails/ProductOption.dart';

class ProductProvider extends ChangeNotifier {
  /// Local in-memory store
  List<ProductOption> availableProducts = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ================= FETCH PRODUCTS =================
  Future<List<ProductOption>> fetchAvailableProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();

      availableProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ensure ID is set from doc
        return ProductOption.fromJson(data);
      }).toList();

      print("🟢 Fetched Products from Firebase = ${availableProducts.length}");

      notifyListeners();
      return availableProducts;
    } catch (e) {
      print("❌ fetchAvailableProducts ERROR: $e");
      notifyListeners();
      return availableProducts;
    }
  }

  /// ================= CREATE / ADD PRODUCT =================
  Future<bool> addProduct(ProductOption product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toJson());

      print("🟡 Add Product Firebase Success: ${product.id}");

      final index = availableProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        availableProducts[index] = product;
      } else {
        availableProducts.add(product);
      }
      notifyListeners();

      return true;
    } catch (e) {
      print("❌ addProduct ERROR: $e");
      return false;
    }
  }

  /// ================= DELETE PRODUCT =================
  Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      print("🔴 Delete Product Firebase Success: $productId");

      availableProducts.removeWhere((p) => p.id == productId);
      notifyListeners();
      
      return true;
    } catch (e) {
      print("❌ deleteProduct ERROR: $e");
      return false;
    }
  }

  void applyVisitConsumption(List<ProductRequest> visitProducts) {
    for (final visitProduct in visitProducts) {
      // find matching product option
      final productOption = availableProducts.firstWhere(
        (p) => p.id == visitProduct.productId,
        orElse: () => const ProductOption(),
      );

      if (productOption.id.isEmpty) continue;

      for (final component in productOption.components) {
        final requiredQty = component.qtyRequired * visitProduct.quantity;

        component.availableStock = component.availableStock - requiredQty;

        if (component.availableStock < 0) {
          component.availableStock = 0; // safety clamp
        }
      }
    }

    // You may also want to sync this specific consumption back to Firebase
    // depending on whether visit consumption actually modifies the global 
    // component stock or is handled differently in the backend.

    notifyListeners();
  }

  List<ComponentStockView> buildStockView(
    ProductOption product,
    int visitQty,
  ) {
    return product.components.map((c) {
      final used = c.qtyRequired * visitQty;
      final before = c.availableStock;
      final after = (before - used).clamp(0, before);

      return ComponentStockView(
        component: c,
        before: before,
        used: used,
        after: after,
      );
    }).toList();
  }
}

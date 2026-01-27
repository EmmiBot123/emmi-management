import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../Model/Marketing/ProductRequest.dart';
import '../../Model/productDetails/ProductComponent.dart';
import '../../Model/productDetails/ProductOption.dart';
import '../../Resources/api_endpoints.dart';

class ProductProvider extends ChangeNotifier {
  /// Local in-memory store
  List<ProductOption> availableProducts = [];

  /// ================= FETCH PRODUCTS =================
  Future<List<ProductOption>> fetchAvailableProducts() async {
    try {
      final url = "${ApiEndpoints.baseUrl}/api/products";
      final uri = Uri.parse(url);

      final response = await http.get(uri);

      print("🔵 Fetch Products API: ${response.statusCode}");
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          availableProducts =
              data.map((e) => ProductOption.fromJson(e)).toList();

          print("🟢 Parsed Products = ${availableProducts.length}");

          notifyListeners();
          return availableProducts;
        }
      }

      availableProducts = [];
      notifyListeners();
      return [];
    } catch (e) {
      print("❌ fetchAvailableProducts ERROR: $e");
      availableProducts = [];
      notifyListeners();
      return [];
    }
  }

  /// ================= CREATE / ADD PRODUCT =================
  Future<bool> addProduct(ProductOption product) async {
    try {
      final url = "${ApiEndpoints.baseUrl}/api/products";
      final uri = Uri.parse(url);

      final body = jsonEncode(product.toJson());

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("🟡 Add Product API: ${response.statusCode}");
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);

        /// backend returns created document — refresh local list entry
        final created = ProductOption.fromJson(json);

        availableProducts.add(created);
        notifyListeners();

        return true;
      }

      return false;
    } catch (e) {
      print("❌ addProduct ERROR: $e");
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      print("in delete");
      final url = "${ApiEndpoints.baseUrl}/api/products/$productId";
      final uri = Uri.parse(url);

      final response = await http.delete(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      print("🔴 Delete Product API: ${response.statusCode}");
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        /// Remove locally
        availableProducts.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      }

      return false;
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

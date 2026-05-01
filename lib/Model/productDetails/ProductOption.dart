import 'package:qubiq_os/Model/productDetails/deliveryHistory.dart';

class ProductOption {
  final String id;
  final String name;
  final List<String> types;
  final List<ProductComponent> components;
  final List<DeliveryHistory> deliveryHistories;

  const ProductOption({
    this.id = "",
    this.name = "",
    this.types = const [],
    this.components = const [],
    this.deliveryHistories = const [],
  });

  factory ProductOption.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProductOption();

    return ProductOption(
      id: json["id"]?.toString() ?? json["_id"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      types: (json["types"] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      components: (json["components"] as List?)
              ?.map((e) => ProductComponent.fromJson(e))
              .toList() ??
          const [],
      deliveryHistories: (json["deliveryHistories"] as List?)
              ?.map((e) => DeliveryHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "types": types,
        "components": components.map((e) => e.toJson()).toList(),
        "deliveryHistories": deliveryHistories.map((e) => e.toJson()).toList(),
      };
}

class ProductComponent {
  final String componentId;
  final String componentName;

  int qtyRequired;
  int availableStock;

  ProductComponent({
    this.componentId = "",
    this.componentName = "",
    this.qtyRequired = 0,
    this.availableStock = 0,
  });

  factory ProductComponent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ProductComponent();

    return ProductComponent(
      componentId: json["componentId"]?.toString() ?? "",
      componentName: json["componentName"]?.toString() ?? "",
      qtyRequired: _toInt(json["qtyRequired"]),
      availableStock: _toInt(json["availableStock"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "componentId": componentId,
        "componentName": componentName,
        "qtyRequired": qtyRequired,
        "availableStock": availableStock,
      };

  /// Safe int parsing (handles null, string, int)
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

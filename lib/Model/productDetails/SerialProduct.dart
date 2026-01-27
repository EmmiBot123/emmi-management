import 'SerialEntry.dart';

class SerialProduct {
  String productName;
  String versionCode; // E1 / E2 etc
  String quantity;
  List<SerialEntry> serials;

  SerialProduct({
    required this.productName,
    required this.quantity,
    required this.versionCode,
    required this.serials,
  });

  factory SerialProduct.fromJson(Map<String, dynamic> json) {
    return SerialProduct(
      productName: json["productName"] ?? "",
      versionCode: json["versionCode"] ?? "",
      quantity: json["quantity"]?.toString() ?? "",
      serials: (json["serials"] as List? ?? [])
          .map((e) => SerialEntry.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "productName": productName,
      "quantity": quantity,
      "versionCode": versionCode,
      "serials": serials.map((e) => e.toJson()).toList(),
    };
  }
}

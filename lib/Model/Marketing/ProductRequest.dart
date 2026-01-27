class ProductRequest {
  String productId;
  String name;
  int quantity;

  ProductRequest({
    required this.productId,
    required this.name,
    required this.quantity,
  });

  factory ProductRequest.fromJson(Map<String, dynamic> json) => ProductRequest(
        productId: json["productId"],
        name: json["name"],
        quantity: json["quantity"],
      );

  Map<String, dynamic> toJson() => {
        "productId": productId,
        "name": name,
        "quantity": quantity,
      };
}

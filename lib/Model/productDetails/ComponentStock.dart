class ComponentStock {
  final String id;
  final String name;
  final int availableStock;

  ComponentStock({
    this.id = "",
    this.name = "",
    this.availableStock = 0,
  });

  factory ComponentStock.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ComponentStock();

    return ComponentStock(
      id: json["_id"] ?? json["id"] ?? "",
      name: json["name"] ?? "",
      availableStock: json["availableStock"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "availableStock": availableStock,
      };
}

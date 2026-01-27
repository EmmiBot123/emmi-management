class PurchaseOrder {
  bool poReceived;
  String poNumber;
  String? poDate;

  PurchaseOrder({
    required this.poReceived,
    required this.poNumber,
    this.poDate,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => PurchaseOrder(
        poReceived: json["poReceived"],
        poNumber: json["poNumber"],
        poDate: json["poDate"],
      );

  Map<String, dynamic> toJson() => {
        "poReceived": poReceived,
        "poNumber": poNumber,
        "poDate": poDate,
      };
}

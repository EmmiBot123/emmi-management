class ImeiEntry {
  String? id;
  String visitId;
  String productName;
  String imei1;
  String imei2;
  String barcodeBase64;

  ImeiEntry({
    this.id,
    required this.visitId,
    required this.productName,
    this.imei1 = "",
    this.imei2 = "",
    this.barcodeBase64 = "",
  });

  factory ImeiEntry.fromJson(Map<String, dynamic> json) {
    return ImeiEntry(
      id: json['id'],
      visitId: json['visitId'] ?? "",
      productName: json['productName'] ?? "",
      imei1: json['imei1'] ?? json['imei'] ?? "",
      imei2: json['imei2'] ?? "",
      barcodeBase64: json['barcodeBase64'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visitId': visitId,
      'productName': productName,
      'imei1': imei1,
      'imei2': imei2,
      'barcodeBase64': barcodeBase64,
    };
  }
}

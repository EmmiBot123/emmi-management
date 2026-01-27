class DeliveryHistory {
  final String id;
  final String schoolId;
  final String date;
  final String productQty;

  const DeliveryHistory({
    this.id = "",
    this.schoolId = "",
    this.date = "",
    this.productQty = "",
  });

  factory DeliveryHistory.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DeliveryHistory();

    return DeliveryHistory(
      id: json["id"]?.toString() ?? json["_id"]?.toString() ?? "",
      schoolId: json["schoolId"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      productQty: json["productQty"].toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "schoolId": schoolId,
        "date": date,
        "productQty": productQty,
      };

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

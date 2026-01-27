import 'SerialProduct.dart';

class SerialAssignment {
  String? id;
  String visitId;
  String? schoolId;
  String createdBy;
  DateTime createdDate;

  List<SerialProduct> products;

  SerialAssignment({
    this.id,
    required this.visitId,
    this.schoolId,
    required this.createdBy,
    required this.createdDate,
    required this.products,
  });

  factory SerialAssignment.fromJson(Map<String, dynamic> json) {
    return SerialAssignment(
      id: json["_id"] ?? json["id"],
      visitId: json["visitId"],
      schoolId: json["schoolId"],
      createdBy: json["createdBy"],
      createdDate: DateTime.parse(json["createdDate"]),
      products: List.from(json["products"])
          .map((e) => SerialProduct.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "visitId": visitId,
      "schoolId": schoolId,
      "createdBy": createdBy,
      "createdDate": createdDate.toIso8601String(),
      "products": products.map((e) => e.toJson()).toList(),
    };
  }
}

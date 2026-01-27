class VisitDetails {
  String status;
  String? visitDate;
  String? revisitDate;
  String statusNotes;

  VisitDetails({
    required this.status,
    this.visitDate,
    this.revisitDate,
    required this.statusNotes,
  });
  VisitDetails copyWith({
    String? status,
    String? revisitDate,
    String? statusNotes,
  }) {
    return VisitDetails(
      status: status ?? this.status,
      visitDate: visitDate,
      revisitDate: revisitDate ?? this.revisitDate,
      statusNotes: statusNotes ?? this.statusNotes,
    );
  }

  factory VisitDetails.fromJson(Map<String, dynamic> json) => VisitDetails(
        status: json["status"],
        visitDate: json["visitDate"],
        revisitDate: json["revisitDate"],
        statusNotes: json["statusNotes"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "visitDate": visitDate,
        "revisitDate": revisitDate,
        "statusNotes": statusNotes,
      };
}

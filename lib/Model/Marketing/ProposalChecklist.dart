class ProposalChecklist {
  bool sent;
  bool whatsapp;
  bool email;
  bool approved;
  String remarks;

  ProposalChecklist({
    required this.sent,
    required this.email,
    required this.whatsapp,
    required this.approved,
    required this.remarks,
  });

  factory ProposalChecklist.fromJson(Map<String, dynamic> json) =>
      ProposalChecklist(
        sent: json["sent"],
        whatsapp: json["whatsapp"],
        email: json["email"],
        approved: json["approved"],
        remarks: json["remarks"],
      );

  Map<String, dynamic> toJson() => {
        "sent": sent,
        "whatsapp": whatsapp,
        "email": email,
        "approved": approved,
        "remarks": remarks,
      };
}

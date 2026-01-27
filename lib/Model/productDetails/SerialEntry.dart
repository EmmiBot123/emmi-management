class SerialEntry {
  String serial;
  String status; // generated | shipped | installed | faulty | replaced
  bool qc;
  String? note;
  String? installationDate;

  SerialEntry({
    required this.serial,
    this.status = "generated",
    this.qc = false,
    this.note,
    this.installationDate,
  });

  factory SerialEntry.fromJson(Map<String, dynamic> json) {
    return SerialEntry(
      serial: json["serial"],
      status: json["status"] ?? "generated",
      qc: json["qc"] ?? false,
      note: json["note"],
      installationDate: json["installationDate"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "serial": serial,
      "status": status,
      "qc": qc,
      "note": note,
      "installationDate": installationDate,
    };
  }
}

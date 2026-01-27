class LabInformation {
  String setupType;
  PCConfig pcConfig;

  LabInformation({
    required this.setupType,
    required this.pcConfig,
  });

  factory LabInformation.fromJson(Map<String, dynamic> json) => LabInformation(
        setupType: json["setupType"],
        pcConfig: PCConfig.fromJson(json["pcConfig"]),
      );

  Map<String, dynamic> toJson() => {
        "setupType": setupType,
        "pcConfig": pcConfig.toJson(),
      };
}

class PCConfig {
  String processor;
  String ram;
  String storageType;
  String storageSize;

  PCConfig({
    required this.processor,
    required this.ram,
    required this.storageType,
    required this.storageSize,
  });

  factory PCConfig.fromJson(Map<String, dynamic> json) => PCConfig(
        processor: json["processor"],
        ram: json["ram"],
        storageType: json["storageType"],
        storageSize: json["storageSize"],
      );

  Map<String, dynamic> toJson() => {
        "processor": processor,
        "ram": ram,
        "storageType": storageType,
        "storageSize": storageSize,
      };
}

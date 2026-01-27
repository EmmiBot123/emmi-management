class BomComponent {
  final String componentId;
  final String componentName;
  final int qtyRequired;

  BomComponent({
    this.componentId = "",
    this.componentName = "",
    this.qtyRequired = 0,
  });

  factory BomComponent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return BomComponent();

    return BomComponent(
      componentId: json["componentId"] ?? "",
      componentName: json["componentName"] ?? "",
      qtyRequired: json["qtyRequired"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        "componentId": componentId,
        "componentName": componentName,
        "qtyRequired": qtyRequired,
      };
}

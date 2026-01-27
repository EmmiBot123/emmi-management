class ParsedAddress {
  final String road;
  final String city;
  final String state;
  final String pinCode;
  final String fullAddress;

  ParsedAddress({
    required this.road,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.fullAddress,
  });

  factory ParsedAddress.fromJson(Map<String, dynamic> data) {
    final address = data["address"] ?? {};

    return ParsedAddress(
      road: address["road"] ?? address["suburb"] ?? "Unknown",
      city: address["city"] ??
          address["town"] ??
          address["district"] ??
          address["village"] ??
          "Unknown",
      state: address["state"] ?? "Unknown",
      pinCode: address["postcode"] ?? "Unknown",
      fullAddress: data["display_name"] ?? "",
    );
  }
}

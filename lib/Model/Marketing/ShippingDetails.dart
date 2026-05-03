class ShippingDetails {
  final String address;
  final String city;
  final String state;
  final String pinCode;
  final String country;
  final String shippingNumber;
  final String contactNumber;
  final String photoUrl;

  /// NEW FIELDS
  final bool passedToInstallation; // For passing to another role
  final bool arrived; // Whether shipment arrived
  final String arrivedDate; // When it arrived
  final String status; // Custom status: "Yet to be picked up", "In Transit", etc.

  ShippingDetails({
    this.address = "",
    this.city = "",
    this.state = "",
    this.pinCode = "",
    this.country = "",
    this.shippingNumber = "",
    this.contactNumber = "",
    this.photoUrl = "",

    /// defaults
    this.passedToInstallation = false,
    this.arrived = false,
    this.arrivedDate = "",
    this.status = "",
  });

  factory ShippingDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ShippingDetails();

    return ShippingDetails(
      address: json["address"] ?? "",
      city: json["city"] ?? "",
      state: json["state"] ?? "",
      pinCode: json["pinCode"] ?? "",
      country: json["country"] ?? "",
      shippingNumber: json["shippingNumber"] ?? "",
      contactNumber: json["contactNumber"] ?? "",
      photoUrl: json["photoUrl"] ?? "",

      /// NEW — safe fallback if backend doesn't send
      passedToInstallation: json["passedToInstallation"] ?? false,
      arrived: json["arrived"] ?? false,
      arrivedDate: json["arrivedDate"] ?? "",
      status: json["status"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "address": address,
        "city": city,
        "state": state,
        "pinCode": pinCode,
        "country": country,
        "shippingNumber": shippingNumber,
        "contactNumber": contactNumber,
        "photoUrl": photoUrl,

        /// NEW
        "passedToInstallation": passedToInstallation,
        "arrived": arrived,
        "arrivedDate": arrivedDate,
        "status": status,
      };

  ShippingDetails copyWith({
    String? address,
    String? city,
    String? state,
    String? pinCode,
    String? country,
    String? shippingNumber,
    String? contactNumber,
    String? photoUrl,
    bool? passedToInstallation,
    bool? arrived,
    String? arrivedDate,
    String? status,
  }) {
    return ShippingDetails(
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      country: country ?? this.country,
      shippingNumber: shippingNumber ?? this.shippingNumber,
      contactNumber: contactNumber ?? this.contactNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      passedToInstallation: passedToInstallation ?? this.passedToInstallation,
      arrived: arrived ?? this.arrived,
      arrivedDate: arrivedDate ?? this.arrivedDate,
      status: status ?? this.status,
    );
  }
}

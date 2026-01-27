class SchoolProfile {
  String name;
  String address;
  String state;
  String city;
  String pinCode;
  List<String> photoUrl;
  double latitude;
  double longitude;
  String googleMapLink;

  SchoolProfile({
    required this.name,
    required this.address,
    required this.state,
    required this.city,
    required this.pinCode,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.googleMapLink,
  });

  SchoolProfile copyWith({
    String? name,
    String? address,
    String? state,
    String? city,
    String? pinCode,
    List<String>? photoUrl,
    double? latitude,
    double? longitude,
    String? googleMapLink,
  }) {
    return SchoolProfile(
      name: name ?? this.name,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      pinCode: pinCode ?? this.pinCode,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      googleMapLink: googleMapLink ?? this.googleMapLink,
    );
  }

  factory SchoolProfile.fromJson(Map<String, dynamic> json) {
    final photoField = json["photoUrl"];

    // Handle flexibility safely:
    List<String> parsedPhotoList = photoField is List
        ? List<String>.from(photoField.map((e) => e.toString()))
        : photoField is String
            ? [photoField]
            : [];

    return SchoolProfile(
        name: json["name"] ?? "",
        address: json["address"] ?? "",
        state: json["state"] ?? "",
        city: json["city"] ?? "",
        pinCode: json["pinCode"] ?? "",
        photoUrl: parsedPhotoList,
        latitude: (json["latitude"] ?? 0).toDouble(),
        longitude: (json["longitude"] ?? 0).toDouble(),
        googleMapLink: json["googleMapLink"] ?? "");
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "address": address,
        "state": state,
        "city": city,
        "pinCode": pinCode,
        "photoUrl": photoUrl,
        "latitude": latitude,
        "longitude": longitude,
        "googleMapLink": googleMapLink,
      };
}

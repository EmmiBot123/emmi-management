class ContactPerson {
  String name;
  String designation;
  String phone;
  String email;

  ContactPerson({
    required this.name,
    required this.designation,
    required this.phone,
    required this.email,
  });

  factory ContactPerson.fromJson(Map<String, dynamic> json) => ContactPerson(
        name: json["name"],
        designation: json["designation"],
        phone: json["phone"],
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "designation": designation,
        "phone": phone,
        "email": email,
      };
}

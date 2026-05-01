// ignore_for_file: non_constant_identifier_names

import 'ContactPerson.dart';
import 'InstallationChecklistItem.dart';
import 'LabInformation.dart';
import 'Payment.dart';
import 'ProductRequest.dart';
import 'ProposalChecklist.dart';
import 'PurchaseOrder.dart';
import 'School_profile_model.dart';
import 'ShippingDetails.dart';
import 'VisitDetails.dart';
import 'shared_user_note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolVisit {
  String? id;
  String createdByUserId;
  String createdByUserName;
  String? assignedUserId;
  String? assignedUserName;
  String? assignedNote;
  String? adminId;
  String? adminName;
  String? schoolCode;
  String? setupToken;
  SchoolProfile schoolProfile;
  List<ContactPerson> contactPersons;

  ProposalChecklist proposalChecklist;
  VisitDetails visitDetails;
  PurchaseOrder purchaseOrder;
  Payment payment;

  ShippingDetails shippingDetails;
  List<ProductRequest> requiredProducts;

  List<InstallationChecklistItem> installationChecklist;

  LabInformation labInformation;
  String? otherRequirements;

  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, String> sharedUsers;
  List<SharedUserNote> sharedNotes;

  SchoolVisit({
    this.id,
    required this.createdByUserId,
    required this.createdByUserName,
    this.assignedUserId,
    this.assignedUserName,
    this.adminId,
    this.adminName,
    this.schoolCode,
    this.setupToken,
    this.assignedNote,
    required this.schoolProfile,
    required this.contactPersons,
    required this.proposalChecklist,
    required this.visitDetails,
    required this.purchaseOrder,
    required this.payment,
    required this.shippingDetails,
    required this.installationChecklist,
    required this.requiredProducts,
    required this.labInformation,
    this.otherRequirements,
    this.createdAt,
    this.updatedAt,
    Map<String, String>? sharedUsers,
    List<SharedUserNote>? sharedNotes,
  })  : sharedUsers = sharedUsers ?? {},
        sharedNotes = sharedNotes ?? [];
  SchoolVisit copyWith({
    SchoolProfile? schoolProfile,
    VisitDetails? visitDetails,
    String? schoolCode,
  }) {
    return SchoolVisit(
      id: id,
      createdByUserId: createdByUserId,
      createdByUserName: createdByUserName,
      assignedUserId: assignedUserId,
      assignedUserName: assignedUserName,
      assignedNote: assignedNote,
      schoolCode: schoolCode ?? this.schoolCode,
      setupToken: setupToken,
      schoolProfile: schoolProfile ?? this.schoolProfile,
      contactPersons: contactPersons,
      proposalChecklist: proposalChecklist,
      visitDetails: visitDetails ?? this.visitDetails,
      purchaseOrder: purchaseOrder,
      payment: payment,
      shippingDetails: shippingDetails,
      requiredProducts: requiredProducts,
      labInformation: labInformation,
      otherRequirements: otherRequirements,
      createdAt: createdAt,
      updatedAt: updatedAt,
      installationChecklist: installationChecklist,
    );
  }

  factory SchoolVisit.fromJson(Map<String, dynamic> json) {
    return SchoolVisit(
      id: json["id"] ?? json["_id"],
      createdByUserId: json["createdByUserId"],
      createdByUserName: json["createdByUserName"],
      adminId: json["adminId"],
      adminName: json["adminName"],
      schoolCode: json["schoolCode"],
      setupToken: json["setupToken"],
      assignedUserId: json["assignedUserId"],
      assignedUserName: json["assignedUserName"],
      assignedNote: json["assignedNote"],
      schoolProfile: SchoolProfile.fromJson(json["schoolProfile"]),
      contactPersons: List.from(json["contactPersons"])
          .map((e) => ContactPerson.fromJson(e))
          .toList(),
      proposalChecklist: ProposalChecklist.fromJson(json["proposalChecklist"]),
      visitDetails: VisitDetails.fromJson(json["visitDetails"]),
      purchaseOrder: PurchaseOrder.fromJson(json["purchaseOrder"]),
      payment: Payment.fromJson(json["payment"]),
      shippingDetails: ShippingDetails.fromJson(json["shippingDetails"]),
      requiredProducts: List.from(json["requiredProducts"])
          .map((e) => ProductRequest.fromJson(e))
          .toList(),
      installationChecklist: (json["installationChecklist"] as List?)
              ?.map((e) => InstallationChecklistItem.fromJson(e))
              .toList() ??
          [],
      sharedUsers: (json["sharedUsers"] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
          {},
      sharedNotes: (json["sharedNotes"] as List?)
              ?.map((e) => SharedUserNote.fromJson(e))
              .toList() ??
          [],
      labInformation: LabInformation.fromJson(json["labInformation"]),
      otherRequirements: json["otherRequirements"],
      createdAt: json["createdAt"] is Timestamp
          ? (json["createdAt"] as Timestamp).toDate()
          : json["createdAt"] != null
              ? DateTime.parse(json["createdAt"].toString())
              : null,
      updatedAt: json["updatedAt"] is Timestamp
          ? (json["updatedAt"] as Timestamp).toDate()
          : json["updatedAt"] != null
              ? DateTime.parse(json["updatedAt"].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "createdByUserId": createdByUserId,
      "createdByUserName": createdByUserName,
      "assignedUserId": assignedUserId,
      "assignedUserName": assignedUserName,
      "adminId": adminId,
      "adminName": adminName,
      "schoolCode": schoolCode,
      "setupToken": setupToken,
      "assignedNote": assignedNote,
      "schoolProfile": schoolProfile.toJson(),
      "contactPersons": contactPersons.map((e) => e.toJson()).toList(),
      "proposalChecklist": proposalChecklist.toJson(),
      "visitDetails": visitDetails.toJson(),
      "purchaseOrder": purchaseOrder.toJson(),
      "payment": payment.toJson(),
      "shippingDetails": shippingDetails.toJson(),
      "installationChecklist":
          installationChecklist.map((e) => e.toJson()).toList(),
      "requiredProducts": requiredProducts.map((e) => e.toJson()).toList(),
      "labInformation": labInformation.toJson(),
      "otherRequirements": otherRequirements,
      "sharedUsers": sharedUsers,
      "sharedNotes": sharedNotes.map((e) => e.toJson()).toList(),
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
  }
}

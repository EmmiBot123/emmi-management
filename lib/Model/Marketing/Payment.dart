class Payment {
  bool advanceTransferred;
  double amount;
  String? transactionId;
  String? transferDate;
  bool paymentConfirmed;

  Payment({
    required this.advanceTransferred,
    required this.amount,
    this.transactionId,
    this.transferDate,
    required this.paymentConfirmed,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        advanceTransferred: json["advanceTransferred"],
        amount: (json["amount"] as num).toDouble(),
        transactionId: json["transactionId"],
        transferDate: json["transferDate"],
        paymentConfirmed: json["paymentConfirmed"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "advanceTransferred": advanceTransferred,
        "amount": amount,
        "transactionId": transactionId,
        "transferDate": transferDate,
        "paymentConfirmed": paymentConfirmed,
      };
}

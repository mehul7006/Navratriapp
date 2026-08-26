class FundCollection {
  final int? id;
  final int userId;
  final double amount;
  final String paymentMethod; // 'cash', 'online'
  final String paymentStatus; // 'pending', 'paid', 'tentative'
  final DateTime? tentativeDate;
  final DateTime? paidDate;
  final int? receivedBy;
  final String? receiptNumber;
  final String? notes;
  final DateTime createdAt;

  // Joined fields
  final String? userName;
  final String? houseNumber;
  final String? receiverName;

  FundCollection({
    this.id,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.tentativeDate,
    this.paidDate,
    this.receivedBy,
    this.receiptNumber,
    this.notes,
    DateTime? createdAt,
    this.userName,
    this.houseNumber,
    this.receiverName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'tentative_date': tentativeDate?.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'received_by': receivedBy,
      'receipt_number': receiptNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FundCollection.fromMap(Map<String, dynamic> map) {
    return FundCollection(
      id: map['id'],
      userId: map['user_id'],
      amount: map['amount']?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'],
      paymentStatus: map['payment_status'],
      tentativeDate: map['tentative_date'] != null
          ? DateTime.parse(map['tentative_date'])
          : null,
      paidDate: map['paid_date'] != null
          ? DateTime.parse(map['paid_date'])
          : null,
      receivedBy: map['received_by'],
      receiptNumber: map['receipt_number'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      userName: map['user_name'],
      houseNumber: map['house_number'],
      receiverName: map['receiver_name'],
    );
  }

  FundCollection copyWith({
    int? id,
    int? userId,
    double? amount,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? tentativeDate,
    DateTime? paidDate,
    int? receivedBy,
    String? receiptNumber,
    String? notes,
  }) {
    return FundCollection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      tentativeDate: tentativeDate ?? this.tentativeDate,
      paidDate: paidDate ?? this.paidDate,
      receivedBy: receivedBy ?? this.receivedBy,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      userName: userName,
      houseNumber: houseNumber,
      receiverName: receiverName,
    );
  }
}

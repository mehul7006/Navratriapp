class Sponsor {
  final int? id;
  final int userId;
  final String? companyName;
  final String? advertisementText;
  final String? advertisementImage;
  final double? sponsorshipAmount;
  final String paymentStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  // Joined fields
  final String? sponsorName;
  final String? mobileNumber;

  Sponsor({
    this.id,
    required this.userId,
    this.companyName,
    this.advertisementText,
    this.advertisementImage,
    this.sponsorshipAmount,
    this.paymentStatus = 'pending',
    this.startDate,
    this.endDate,
    this.isActive = true,
    DateTime? createdAt,
    this.sponsorName,
    this.mobileNumber,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'company_name': companyName,
      'advertisement_text': advertisementText,
      'advertisement_image': advertisementImage,
      'sponsorship_amount': sponsorshipAmount,
      'payment_status': paymentStatus,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Sponsor.fromMap(Map<String, dynamic> map) {
    return Sponsor(
      id: map['id'],
      userId: map['user_id'],
      companyName: map['company_name'],
      advertisementText: map['advertisement_text'],
      advertisementImage: map['advertisement_image'],
      sponsorshipAmount: map['sponsorship_amount']?.toDouble(),
      paymentStatus: map['payment_status'],
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'])
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'])
          : null,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      sponsorName: map['sponsor_name'],
      mobileNumber: map['mobile_number'],
    );
  }

  Sponsor copyWith({
    int? id,
    int? userId,
    String? companyName,
    String? advertisementText,
    String? advertisementImage,
    double? sponsorshipAmount,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Sponsor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      advertisementText: advertisementText ?? this.advertisementText,
      advertisementImage: advertisementImage ?? this.advertisementImage,
      sponsorshipAmount: sponsorshipAmount ?? this.sponsorshipAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      sponsorName: sponsorName,
      mobileNumber: mobileNumber,
    );
  }
}

class ExpenseCategory {
  final int? id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  ExpenseCategory({
    this.id,
    required this.name,
    this.description,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class Expense {
  final int? id;
  final int categoryId;
  final String itemName;
  final double amount;
  final String? paidTo;
  final int? paidBy;
  final String paymentMethod;
  final String? receiptImage;
  final String? notes;
  final DateTime? expenseDate;
  final DateTime createdAt;

  // Joined fields
  final String? categoryName;
  final String? payerName;

  Expense({
    this.id,
    required this.categoryId,
    required this.itemName,
    required this.amount,
    this.paidTo,
    this.paidBy,
    this.paymentMethod = 'cash',
    this.receiptImage,
    this.notes,
    this.expenseDate,
    DateTime? createdAt,
    this.categoryName,
    this.payerName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'item_name': itemName,
      'amount': amount,
      'paid_to': paidTo,
      'paid_by': paidBy,
      'payment_method': paymentMethod,
      'receipt_image': receiptImage,
      'notes': notes,
      'expense_date': expenseDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      categoryId: map['category_id'],
      itemName: map['item_name'],
      amount: map['amount']?.toDouble() ?? 0.0,
      paidTo: map['paid_to'],
      paidBy: map['paid_by'],
      paymentMethod: map['payment_method'],
      receiptImage: map['receipt_image'],
      notes: map['notes'],
      expenseDate: map['expense_date'] != null
          ? DateTime.parse(map['expense_date'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      categoryName: map['category_name'],
      payerName: map['payer_name'],
    );
  }

  Expense copyWith({
    int? id,
    int? categoryId,
    String? itemName,
    double? amount,
    String? paidTo,
    int? paidBy,
    String? paymentMethod,
    String? receiptImage,
    String? notes,
    DateTime? expenseDate,
  }) {
    return Expense(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      itemName: itemName ?? this.itemName,
      amount: amount ?? this.amount,
      paidTo: paidTo ?? this.paidTo,
      paidBy: paidBy ?? this.paidBy,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptImage: receiptImage ?? this.receiptImage,
      notes: notes ?? this.notes,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt,
      categoryName: categoryName,
      payerName: payerName,
    );
  }
}

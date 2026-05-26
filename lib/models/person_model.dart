class PersonModel {
  String? id;
  String name;
  String? phone;
  String? email;
  DateTime? createdAt;

  PersonModel({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    return PersonModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }
}

class TransactionPerson {
  String? id;
  String transactionId;
  String personId;
  String personName; // For UI display
  double amount;
  String direction; // 'paid', 'owes', 'lent'
  String status; // 'pending', 'settled', 'partial'
  double settledAmount;
  int? dueDate;

  TransactionPerson({
    this.id,
    required this.transactionId,
    required this.personId,
    required this.personName,
    required this.amount,
    required this.direction,
    required this.status,
    this.settledAmount = 0,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'personId': personId,
      'amount': amount,
      'direction': direction,
      'status': status,
      'settledAmount': settledAmount,
      'dueDate': dueDate,
    };
  }

  factory TransactionPerson.fromMap(Map<String, dynamic> map) {
    return TransactionPerson(
      id: map['id'],
      transactionId: map['transactionId'],
      personId: map['personId'],
      personName: '', // Will be filled separately
      amount: map['amount'],
      direction: map['direction'],
      status: map['status'],
      settledAmount: map['settledAmount'] ?? 0,
      dueDate: map['dueDate'],
    );
  }
}
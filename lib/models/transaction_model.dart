class TransactionModel {
  String? id;
  double amount;
  DateTime date;
  String description;
  String category;
  String paymentMode;
  String? location;
  String? notes;
  List<PersonShare>? people;
  List<String>? attachmentIds;
  DateTime? createdAt;
  DateTime? updatedAt;

  TransactionModel({
    this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.category,
    required this.paymentMode,
    this.location,
    this.notes,
    this.people,
    this.attachmentIds,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'category': category,
      'paymentMode': paymentMode,
      'location': location,
      'notes': notes,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      description: map['description'],
      category: map['category'],
      paymentMode: map['paymentMode'],
      location: map['location'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }
}

class PersonShare {
  String personId;
  String personName;
  double amount;
  String direction; // 'paid', 'owes', 'lent'
  String status; // 'pending', 'settled'

  PersonShare({
    required this.personId,
    required this.personName,
    required this.amount,
    required this.direction,
    required this.status,
  });
}
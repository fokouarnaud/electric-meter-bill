import '../../domain/entities/bill.dart';

class BillModel extends Bill {
  const BillModel({
    required super.id,
    required super.meterId,
    required super.clientName,
    required super.previousReading,
    required super.currentReading,
    required super.consumption,
    required super.amount,
    required super.startDate,
    required super.endDate,
    required super.generatedDate,
    required super.date,
    required super.dueDate,
    required super.createdAt,
    super.notes,
    required super.isPaid,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      meterId: json['meter_id'] as String,
      clientName: json['client_name'] as String,
      previousReading: json['previous_reading'] as double,
      currentReading: json['current_reading'] as double,
      consumption: json['consumption'] as double,
      amount: json['amount'] as double,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      generatedDate: DateTime.parse(json['generated_date'] as String),
      date: DateTime.parse(json['date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
      isPaid: json['is_paid'] as bool,
    );
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] as String,
      meterId: map['meter_id'] as String,
      clientName: map['client_name'] as String,
      previousReading: map['previous_reading'] as double,
      currentReading: map['current_reading'] as double,
      consumption: map['consumption'] as double,
      amount: map['amount'] as double,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      generatedDate: DateTime.parse(map['generated_date'] as String),
      date: DateTime.parse(map['date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      notes: map['notes'] as String?,
      isPaid: map['is_paid'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meter_id': meterId,
      'client_name': clientName,
      'previous_reading': previousReading,
      'current_reading': currentReading,
      'consumption': consumption,
      'amount': amount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'generated_date': generatedDate.toIso8601String(),
      'date': date.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'is_paid': isPaid,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meter_id': meterId,
      'client_name': clientName,
      'previous_reading': previousReading,
      'current_reading': currentReading,
      'consumption': consumption,
      'amount': amount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'generated_date': generatedDate.toIso8601String(),
      'date': date.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'is_paid': isPaid ? 1 : 0,
    };
  }

  @override
  BillModel copyWith({
    String? id,
    String? meterId,
    String? clientName,
    double? previousReading,
    double? currentReading,
    double? consumption,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? generatedDate,
    DateTime? date,
    DateTime? dueDate,
    String? notes,
    bool? isPaid,
    DateTime? createdAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      meterId: meterId ?? this.meterId,
      clientName: clientName ?? this.clientName,
      previousReading: previousReading ?? this.previousReading,
      currentReading: currentReading ?? this.currentReading,
      consumption: consumption ?? this.consumption,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      generatedDate: generatedDate ?? this.generatedDate,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

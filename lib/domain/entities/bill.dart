class Bill {
  final String id;
  final String meterId;
  final String clientName;
  final double previousReading;
  final double currentReading;
  final double consumption;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedDate;
  final DateTime date;
  final DateTime dueDate;
  final String? notes;
  final bool isPaid;
  final DateTime createdAt;

  const Bill({
    required this.id,
    required this.meterId,
    required this.clientName,
    required this.previousReading,
    required this.currentReading,
    required this.consumption,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.generatedDate,
    required this.date,
    required this.dueDate,
    this.notes,
    required this.isPaid,
    required this.createdAt,
  });

  Bill copyWith({
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
    return Bill(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bill &&
        other.id == id &&
        other.meterId == meterId &&
        other.clientName == clientName &&
        other.previousReading == previousReading &&
        other.currentReading == currentReading &&
        other.consumption == consumption &&
        other.amount == amount &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.generatedDate == generatedDate &&
        other.date == date &&
        other.dueDate == dueDate &&
        other.notes == notes &&
        other.isPaid == isPaid &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        meterId.hashCode ^
        clientName.hashCode ^
        previousReading.hashCode ^
        currentReading.hashCode ^
        consumption.hashCode ^
        amount.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        generatedDate.hashCode ^
        date.hashCode ^
        dueDate.hashCode ^
        notes.hashCode ^
        isPaid.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Bill(id: $id, meterId: $meterId, clientName: $clientName, '
        'previousReading: $previousReading, currentReading: $currentReading, '
        'consumption: $consumption, amount: $amount, startDate: $startDate, '
        'endDate: $endDate, generatedDate: $generatedDate, date: $date, '
        'dueDate: $dueDate, notes: $notes, isPaid: $isPaid, '
        'createdAt: $createdAt)';
  }
}

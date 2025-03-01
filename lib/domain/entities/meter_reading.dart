class MeterReading {
  final String id;
  final String meterId;
  final double value;
  final String imageUrl;
  final DateTime readingDate;
  final bool isVerified;
  final String? notes;
  final double? consumption;

  const MeterReading({
    required this.id,
    required this.meterId,
    required this.value,
    required this.imageUrl,
    required this.readingDate,
    required this.isVerified,
    this.notes,
    this.consumption,
  });

  MeterReading copyWith({
    String? id,
    String? meterId,
    double? value,
    String? imageUrl,
    DateTime? readingDate,
    bool? isVerified,
    String? notes,
    double? consumption,
  }) {
    return MeterReading(
      id: id ?? this.id,
      meterId: meterId ?? this.meterId,
      value: value ?? this.value,
      imageUrl: imageUrl ?? this.imageUrl,
      readingDate: readingDate ?? this.readingDate,
      isVerified: isVerified ?? this.isVerified,
      notes: notes ?? this.notes,
      consumption: consumption ?? this.consumption,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeterReading &&
        other.id == id &&
        other.meterId == meterId &&
        other.value == value &&
        other.imageUrl == imageUrl &&
        other.readingDate == readingDate &&
        other.isVerified == isVerified &&
        other.notes == notes &&
        other.consumption == consumption;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        meterId.hashCode ^
        value.hashCode ^
        imageUrl.hashCode ^
        readingDate.hashCode ^
        isVerified.hashCode ^
        notes.hashCode ^
        consumption.hashCode;
  }

  @override
  String toString() {
    return 'MeterReading(id: $id, meterId: $meterId, value: $value, '
        'imageUrl: $imageUrl, readingDate: $readingDate, '
        'isVerified: $isVerified, notes: $notes, consumption: $consumption)';
  }

  // Helper method to calculate consumption from previous reading
  MeterReading withConsumptionFromPrevious(MeterReading? previousReading) {
    if (previousReading == null) {
      return this;
    }
    return copyWith(
      consumption: value - previousReading.value,
    );
  }
}

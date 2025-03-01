import '../../domain/entities/meter_reading.dart';

class MeterReadingModel extends MeterReading {
  final DateTime createdAt;

  const MeterReadingModel({
    required super.id,
    required super.meterId,
    required super.value,
    required super.imageUrl,
    required super.readingDate,
    required super.isVerified,
    required this.createdAt,
    super.notes,
    super.consumption,
  });

  factory MeterReadingModel.fromJson(Map<String, dynamic> json) {
    return MeterReadingModel(
      id: json['id'] as String,
      meterId: json['meter_id'] as String,
      value: (json['value'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      readingDate: DateTime.parse(json['reading_date'] as String),
      isVerified: json['is_verified'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
      consumption: json['consumption'] == null
          ? null
          : (json['consumption'] as num).toDouble(),
    );
  }

  factory MeterReadingModel.fromMap(Map<String, dynamic> map) {
    return MeterReadingModel(
      id: map['id'] as String,
      meterId: map['meter_id'] as String,
      value: (map['value'] as num).toDouble(),
      imageUrl: map['image_url'] as String,
      readingDate: DateTime.parse(map['reading_date'] as String),
      isVerified: map['is_verified'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      notes: map['notes'] as String?,
      consumption: map['consumption'] == null
          ? null
          : (map['consumption'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meter_id': meterId,
      'value': value,
      'image_url': imageUrl,
      'reading_date': readingDate.toIso8601String(),
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'consumption': consumption,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meter_id': meterId,
      'value': value,
      'image_url': imageUrl,
      'reading_date': readingDate.toIso8601String(),
      'is_verified': isVerified ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'consumption': consumption,
    };
  }

  @override
  MeterReadingModel copyWith({
    String? id,
    String? meterId,
    double? value,
    String? imageUrl,
    DateTime? readingDate,
    bool? isVerified,
    String? notes,
    double? consumption,
    DateTime? createdAt,
  }) {
    return MeterReadingModel(
      id: id ?? this.id,
      meterId: meterId ?? this.meterId,
      value: value ?? this.value,
      imageUrl: imageUrl ?? this.imageUrl,
      readingDate: readingDate ?? this.readingDate,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      consumption: consumption ?? this.consumption,
    );
  }

  factory MeterReadingModel.fromMeterReading(MeterReading reading) {
    if (reading is MeterReadingModel) {
      return reading;
    }
    return MeterReadingModel(
      id: reading.id,
      meterId: reading.meterId,
      value: reading.value,
      imageUrl: reading.imageUrl,
      readingDate: reading.readingDate,
      isVerified: reading.isVerified,
      createdAt: DateTime.now(),
      notes: reading.notes,
      consumption: reading.consumption,
    );
  }
}

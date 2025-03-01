import '../../domain/entities/meter.dart';

class MeterModel extends Meter {
  const MeterModel({
    required super.id,
    required super.name,
    required super.location,
    required super.clientName,
    required super.pricePerKwh,
    required super.createdAt,
    required super.updatedAt,
    super.contactPhone,
    super.contactEmail,
    super.contactName,
  });

  factory MeterModel.fromJson(Map<String, dynamic> json) {
    return MeterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      clientName: json['client_name'] as String,
      pricePerKwh: (json['price_per_kwh'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactName: json['contact_name'] as String?,
    );
  }

  factory MeterModel.fromMap(Map<String, dynamic> map) {
    return MeterModel(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      clientName: map['client_name'] as String,
      pricePerKwh: (map['price_per_kwh'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      contactPhone: map['contact_phone'] as String?,
      contactEmail: map['contact_email'] as String?,
      contactName: map['contact_name'] as String?,
    );
  }

  factory MeterModel.fromMeter(Meter meter) {
    return MeterModel(
      id: meter.id,
      name: meter.name,
      location: meter.location,
      clientName: meter.clientName,
      pricePerKwh: meter.pricePerKwh,
      createdAt: meter.createdAt,
      updatedAt: meter.updatedAt,
      contactPhone: meter.contactPhone,
      contactEmail: meter.contactEmail,
      contactName: meter.contactName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'client_name': clientName,
      'price_per_kwh': pricePerKwh,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'contact_name': contactName,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'client_name': clientName,
      'price_per_kwh': pricePerKwh,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'contact_name': contactName,
    };
  }

  @override
  MeterModel copyWith({
    String? id,
    String? name,
    String? location,
    String? clientName,
    double? pricePerKwh,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contactPhone,
    String? contactEmail,
    String? contactName,
  }) {
    return MeterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      clientName: clientName ?? this.clientName,
      pricePerKwh: pricePerKwh ?? this.pricePerKwh,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      contactName: contactName ?? this.contactName,
    );
  }
}

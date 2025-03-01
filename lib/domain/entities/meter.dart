class Meter {
  final String id;
  final String name;
  final String location;
  final String clientName;
  final double pricePerKwh;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? contactPhone;
  final String? contactEmail;
  final String? contactName;

  const Meter({
    required this.id,
    required this.name,
    required this.location,
    required this.clientName,
    required this.pricePerKwh,
    required this.createdAt,
    required this.updatedAt,
    this.contactPhone,
    this.contactEmail,
    this.contactName,
  });

  Meter copyWith({
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
    return Meter(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Meter &&
        other.id == id &&
        other.name == name &&
        other.location == location &&
        other.clientName == clientName &&
        other.pricePerKwh == pricePerKwh &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.contactPhone == contactPhone &&
        other.contactEmail == contactEmail &&
        other.contactName == contactName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        location.hashCode ^
        clientName.hashCode ^
        pricePerKwh.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        contactPhone.hashCode ^
        contactEmail.hashCode ^
        contactName.hashCode;
  }

  @override
  String toString() {
    return 'Meter(id: $id, name: $name, location: $location, clientName: $clientName, '
        'pricePerKwh: $pricePerKwh, createdAt: $createdAt, updatedAt: $updatedAt, '
        'contactPhone: $contactPhone, contactEmail: $contactEmail, contactName: $contactName)';
  }
}

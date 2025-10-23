/// Recipient details for package delivery
/// Recipient doesn't need to have a CrowdWave account
class RecipientDetails {
  final String name;
  final String phone;
  final String? email; // Optional - recipient may not have email
  final String? notes; // Special delivery instructions for recipient
  final String? alternativePhone; // Backup contact number

  const RecipientDetails({
    required this.name,
    required this.phone,
    this.email,
    this.notes,
    this.alternativePhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'notes': notes,
      'alternativePhone': alternativePhone,
    };
  }

  factory RecipientDetails.fromMap(Map<String, dynamic> map) {
    return RecipientDetails(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      notes: map['notes'],
      alternativePhone: map['alternativePhone'],
    );
  }

  RecipientDetails copyWith({
    String? name,
    String? phone,
    String? email,
    String? notes,
    String? alternativePhone,
  }) {
    return RecipientDetails(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      alternativePhone: alternativePhone ?? this.alternativePhone,
    );
  }

  @override
  String toString() {
    return 'RecipientDetails(name: $name, phone: $phone, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecipientDetails &&
        other.name == name &&
        other.phone == phone &&
        other.email == email &&
        other.notes == notes &&
        other.alternativePhone == alternativePhone;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        notes.hashCode ^
        alternativePhone.hashCode;
  }
}

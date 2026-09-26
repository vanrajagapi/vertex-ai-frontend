class Patient {
  final String id;
  final String name;
  final String age;
  final String gender;
  final String contact;
  final String email;
  final String address;
  final String pmjayNumber;
  final String dob;
  final String createdAt;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    this.email = '',
    this.address = '',
    this.pmjayNumber = '',
    this.dob = '',
    this.createdAt = '',
  });

  Patient copyWith({
    String? id,
    String? name,
    String? age,
    String? gender,
    String? contact,
    String? email,
    String? address,
    String? pmjayNumber,
    String? dob,
    String? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      address: address ?? this.address,
      pmjayNumber: pmjayNumber ?? this.pmjayNumber,
      dob: dob ?? this.dob,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: (json['patient_id'] ?? '').toString(),
      name: json['name'] ?? '',
      age: (json['age'] ?? '').toString(),
      gender: json['gender'] ?? '',
      contact: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      pmjayNumber: json['pmjay_number'] ?? '',
      dob: json['dob'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dob': dob,
      'age': int.tryParse(age) ?? 0,
      'gender': gender,
      'pmjay_number': pmjayNumber,
      'phone': contact.isEmpty ? null : contact,
    };
  }
}


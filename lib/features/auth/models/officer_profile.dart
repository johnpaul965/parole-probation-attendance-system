class OfficerProfile {
  const OfficerProfile({
    required this.id,
    required this.name,
    required this.email,
    this.contact,
    this.office,
    this.profileImage,
  });

  final String id;
  final String name;
  final String email;
  final String? contact;
  final String? office;
  final String? profileImage;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory OfficerProfile.fromMap(String id, Map<String, dynamic> map) {
    return OfficerProfile(
      id: id,
      name: map['name'] as String? ?? map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      contact: map['contact'] as String? ?? map['phone'] as String?,
      office: map['office'] as String? ?? map['department'] as String?,
      profileImage: map['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'contact': contact,
        'office': office,
        'profileImage': profileImage,
      };
}

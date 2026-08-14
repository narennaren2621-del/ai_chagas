class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.provider,
    this.photoUrl,
  });

  final String name;
  final String email;
  final String provider;
  final String? photoUrl;
}

class PatientDetails {
  const PatientDetails({
    required this.gender,
    required this.fullName,
    required this.dateOfBirth,
    required this.gmailId,
    required this.city,
    required this.age,
  });

  final String gender;
  final String fullName;
  final DateTime dateOfBirth;
  final String gmailId;
  final String city;
  final int age;
}

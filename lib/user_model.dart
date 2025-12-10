// lib/user_model.dart

// Enum for user zones (Kids or Adult)
enum UserZone { kids, adult }

class UserProfile {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String dateOfBirth;
  final int age;
  final String gender;
  final double screenTimeLimit;
  final String password;

  UserProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.screenTimeLimit,
    required this.password,
  });

  // Convert to Map for storage or API calls
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'gender': gender,
      'screenTimeLimit': screenTimeLimit,
      'password': password,
    };
  }

  // Create from Map (for loading saved data)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      screenTimeLimit: map['screenTimeLimit'] ?? 2.0,
      password: map['password'] ?? '',
    );
  }

  // Create from Firestore document (excludes password for security)
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String email) {
    return UserProfile(
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: email,
      dateOfBirth: data['dateOfBirth'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      screenTimeLimit: (data['screenTimeLimit'] ?? 2.0).toDouble(),
      password: '', // Don't store password in model for security
    );
  }

  // Convert to Firestore format (excludes password for security)
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'gender': gender,
      'screenTimeLimit': screenTimeLimit,
      // Don't include password in Firestore
    };
  }

  // Create a copy with updated values
  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? dateOfBirth,
    int? age,
    String? gender,
    double? screenTimeLimit,
    String? password,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      screenTimeLimit: screenTimeLimit ?? this.screenTimeLimit,
      password: password ?? this.password,
    );
  }
}

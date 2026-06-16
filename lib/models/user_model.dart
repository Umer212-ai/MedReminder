import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, familyMember, caregiver }

UserRole roleFromString(String? value) {
  switch (value) {
    case 'family_member':
      return UserRole.familyMember;
    case 'caregiver':
      return UserRole.caregiver;
    default:
      return UserRole.patient;
  }
}

String roleToString(UserRole role) {
  switch (role) {
    case UserRole.familyMember:
      return 'family_member';
    case UserRole.caregiver:
      return 'caregiver';
    case UserRole.patient:
      return 'patient';
  }
}

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final int age;
  final String phoneNumber;
  final String emergencyContact;
  final UserRole role;
  final String? photoUrl;
  final String? fcmToken;
  final String? specialty;
  final String? clinicName;
  final String? availableTiming;
  final String? location;
  final String? qualification;
  final String? experience;
  final String? bio;
  final String? gender;
  final String? medicalSummary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.age,
    required this.phoneNumber,
    required this.emergencyContact,
    required this.role,
    this.photoUrl,
    this.fcmToken,
    this.specialty,
    this.clinicName,
    this.availableTiming,
    this.location,
    this.qualification,
    this.experience,
    this.bio,
    this.gender,
    this.medicalSummary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      emergencyContact: data['emergencyContact'] as String? ?? '',
      role: roleFromString(data['role'] as String?),
      photoUrl: data['photoUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
      specialty: data['specialty'] as String?,
      clinicName: data['clinicName'] as String?,
      availableTiming: data['availableTiming'] as String?,
      location: data['location'] as String?,
      qualification: data['qualification'] as String?,
      experience: data['experience'] as String?,
      bio: data['bio'] as String?,
      gender: data['gender'] as String?,
      medicalSummary: data['medicalSummary'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'fullName': fullName,
        'age': age,
        'phoneNumber': phoneNumber,
        'emergencyContact': emergencyContact,
        'role': roleToString(role),
        'photoUrl': photoUrl,
        'fcmToken': fcmToken,
        'specialty': specialty,
        'clinicName': clinicName,
        'availableTiming': availableTiming,
        'location': location,
        'qualification': qualification,
        'experience': experience,
        'bio': bio,
        'gender': gender,
        'medicalSummary': medicalSummary,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  UserModel copyWith({
    String? fullName,
    int? age,
    String? phoneNumber,
    String? emergencyContact,
    UserRole? role,
    String? photoUrl,
    String? fcmToken,
    String? specialty,
    String? clinicName,
    String? availableTiming,
    String? location,
    String? qualification,
    String? experience,
    String? bio,
    String? gender,
    String? medicalSummary,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      specialty: specialty ?? this.specialty,
      clinicName: clinicName ?? this.clinicName,
      availableTiming: availableTiming ?? this.availableTiming,
      location: location ?? this.location,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      medicalSummary: medicalSummary ?? this.medicalSummary,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

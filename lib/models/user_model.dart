// ─────────────────────────────────────────────
//  user_model.dart
// ─────────────────────────────────────────────

enum VerificationStatus { pending, verified, rejected }

class UserModel {
  final String name;
  final String phone;
  final String college;
  final String hostel;
  final String roomNumber;
  final VerificationStatus verificationStatus;
  final String? messCardPath;
  final String? idCardPath;

  UserModel({
    required this.name,
    required this.phone,
    required this.college,
    required this.hostel,
    required this.roomNumber,
    this.verificationStatus = VerificationStatus.pending,
    this.messCardPath,
    this.idCardPath,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? college,
    String? hostel,
    String? roomNumber,
    VerificationStatus? verificationStatus,
    String? messCardPath,
    String? idCardPath,
  }) {
    return UserModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      college: college ?? this.college,
      hostel: hostel ?? this.hostel,
      roomNumber: roomNumber ?? this.roomNumber,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      messCardPath: messCardPath ?? this.messCardPath,
      idCardPath: idCardPath ?? this.idCardPath,
    );
  }
}

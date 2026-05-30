enum UserRole {
  student('Student', 'Student', 'student', '🎓'),
  warden('Warden', 'Warden', 'warden', '🛡️'),
  cleaning('Cleaning Staff', 'Cleaning', 'cleaner', '🧹'),
  canteen('Canteen Staff', 'Canteen', 'canteen', '🍽️'),
  maintenance('Maintenance Staff', 'Maintenance', 'warden', '🔧');

  final String label;
  final String shortLabel;
  final String dbRoleValue;
  final String icon;

  const UserRole(this.label, this.shortLabel, this.dbRoleValue, this.icon);
}

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? roomNumber;
  final String? hostel;
  final String? college;
  final String? department;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.roomNumber,
    this.hostel,
    this.college,
    this.department,
  });

  factory AppUser.mock(String phone, UserRole role) {
    switch (role) {
      case UserRole.student:
        return AppUser(
          id: 'STU001',
          name: 'Arjun Sharma',
          phone: phone,
          role: role,
          roomNumber: 'B-204',
          hostel: 'RV Main Hostel',
          college: 'RVCE',
          department: 'CSE',
        );
      case UserRole.warden:
        return AppUser(
          id: 'WDN001',
          name: 'Dr. Rajesh Verma',
          phone: phone,
          role: role,
          college: 'RVCE',
          department: 'Administration',
        );
      case UserRole.cleaning:
        return AppUser(
          id: 'CLN001',
          name: 'Ramesh Kumar',
          phone: phone,
          role: role,
          college: 'RVCE',
          department: 'Housekeeping',
        );
      case UserRole.canteen:
        return AppUser(
          id: 'CAN001',
          name: 'Suresh Patel',
          phone: phone,
          role: role,
          college: 'RVCE',
          department: 'Canteen',
        );
      case UserRole.maintenance:
        return AppUser(
          id: 'MNT001',
          name: 'Vikram Singh',
          phone: phone,
          role: role,
          college: 'RVCE',
          department: 'Maintenance',
        );
    }
  }
}


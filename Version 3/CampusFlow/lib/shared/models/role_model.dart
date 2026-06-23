enum UserRole {
  admin, // Full access
  lecturer, // Course-specific access
  student, // Personal access only
  parent, // Child access only
  finance, // Fee management only
}

class Role {
  final UserRole role;
  final List<String> permissions;

  Role({
    required this.role,
    required this.permissions,
  });

  // Check if user has permission
  bool hasPermission(String permission) {
    return permissions.contains(permission) || permissions.contains('*');
  }

  // Get role from user type
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'lecturer':
        return UserRole.lecturer;
      case 'student':
        return UserRole.student;
      case 'parent':
        return UserRole.parent;
      case 'finance':
        return UserRole.finance;
      default:
        return UserRole.student;
    }
  }

  // Get permissions for role
  static Role getRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Role(
          role: role,
          permissions: ['*'], // Full access
        );
      case UserRole.lecturer:
        return Role(
          role: role,
          permissions: [
            'view_students',
            'mark_attendance',
            'view_attendance',
            'grade_students',
          ],
        );
      case UserRole.student:
        return Role(
          role: role,
          permissions: [
            'view_profile',
            'view_attendance',
            'view_courses',
            'view_fees',
            'pay_fees',
          ],
        );
      case UserRole.parent:
        return Role(
          role: role,
          permissions: [
            'view_child_profile',
            'view_child_attendance',
            'view_child_fees',
          ],
        );
      case UserRole.finance:
        return Role(
          role: role,
          permissions: [
            'view_fees',
            'manage_payments',
            'view_students',
          ],
        );
    }
  }
}

enum UserRole {
  officer,
  parolee;

  String get label {
    switch (this) {
      case UserRole.officer:
        return 'Officer';
      case UserRole.parolee:
        return 'Parolee';
    }
  }

  String get routePrefix {
    switch (this) {
      case UserRole.officer:
        return '/officer';
      case UserRole.parolee:
        return '/parolee';
    }
  }

  /// Maps legacy `admin` accounts to officer for migration.
  static UserRole fromString(String value) {
    if (value == 'admin') return UserRole.officer;
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.parolee,
    );
  }
}

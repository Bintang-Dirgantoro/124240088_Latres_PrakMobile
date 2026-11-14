class AppUser {
  final String username;
  final String password;
  final String fullName;

  AppUser({
    required this.username,
    required this.password,
    required this.fullName,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'fullName': fullName,
    };
  }

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    return AppUser(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      fullName: map['fullName'] ?? '',
    );
  }
}

class WifiPassword {
  final String password;
  final DateTime expiresAt;

  WifiPassword({required this.password, required this.expiresAt});

  factory WifiPassword.fromJson(Map<String, dynamic> data) {
    return WifiPassword(
      password: data['password'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'password': password,
        'expiresAt': expiresAt.toIso8601String(),
      };
}

class UserModel {
  final int idUser;
  final String email;
  final String role;
  final String? token;

  UserModel({
    required this.idUser,
    required this.email,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Menangani id_user yang bisa berupa string atau int
    int parseIdUser(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return UserModel(
      idUser: parseIdUser(json['id_user']),
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_user': idUser, 'email': email, 'role': role, 'token': token};
  }

  UserModel copyWith({
    int? idUser,
    String? email,
    String? role,
    String? token,
  }) {
    return UserModel(
      idUser: idUser ?? this.idUser,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }
}

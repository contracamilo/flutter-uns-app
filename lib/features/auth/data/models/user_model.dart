import 'package:unisalle/features/auth/domain/entities/user.dart';

/// Modelo de Datos para `User`. Vive en la capa de Data y conoce
/// el formato JSON del backend Node.js. Convierte el payload remoto
/// en una entidad de dominio limpia.
///
/// Patrón: extiende la entidad y añade `fromJson` / `toJson`.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.photoUrl,
    super.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawRoles = json['roles'];
    return UserModel(
      id: rawId is String ? rawId : rawId.toString(),
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      photoUrl: json['image'] as String? ?? json['photoUrl'] as String?,
      roles: rawRoles is List
          ? rawRoles.map((r) => r.toString()).toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (photoUrl != null) 'image': photoUrl,
        'roles': roles,
      };
}

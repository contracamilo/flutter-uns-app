import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa al usuario autenticado.
///
/// Pertenece a la capa de Dominio: no depende de Flutter, ni de
/// serialización JSON, ni de ningún framework externo más allá
/// de Equatable. La conversión desde/hacia JSON vive en
/// `data/models/user_model.dart`.
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.roles = const [],
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> roles;

  bool hasRole(String role) => roles.contains(role);

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    List<String>? roles,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      roles: roles ?? this.roles,
    );
  }

  @override
  List<Object?> get props => [id, name, email, photoUrl, roles];
}

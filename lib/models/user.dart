import 'package:flutter/foundation.dart' show listEquals;

class User {
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

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawRoles = json['roles'];
    return User(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.photoUrl == photoUrl &&
        listEquals(other.roles, roles);
  }

  @override
  int get hashCode =>
      Object.hash(id, name, email, photoUrl, Object.hashAll(roles));

  @override
  String toString() =>
      'User(id: $id, name: $name, email: $email, photoUrl: $photoUrl, roles: $roles)';
}

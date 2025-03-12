class User {
  final String id;
  final String name;
  final String email;
  final String? authToken;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.authToken,
  });

  /// Creates a User from a Map (JSON)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      authToken: map['authToken'],
    );
  }

  /// Converts User to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'authToken': authToken,
    };
  }

  /// Creates a copy of the current User with updated properties
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? authToken,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      authToken: authToken ?? this.authToken,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, authToken: $authToken)';
  }
}


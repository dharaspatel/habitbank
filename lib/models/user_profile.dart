class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String? email;
  final String? photoUrl;

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? '',
        email: map['email'] as String?,
        photoUrl: map['photo_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'photo_url': photoUrl,
      };
}

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> friends;
  final List<String> sentRequests;
  final List<String> receivedRequests;
  final bool isPrivate; // 1. Gizli Profil Alanı

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.friends = const [],
    this.sentRequests = const [],
    this.receivedRequests = const [],
    this.isPrivate = false, // Varsayılan değer false
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      friends: List<String>.from(map['friends'] ?? []),
      sentRequests: List<String>.from(map['sentRequests'] ?? []),
      receivedRequests: List<String>.from(map['receivedRequests'] ?? []),
      isPrivate: map['isPrivate'] ?? false, // Map'ten oku
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'friends': friends,
      'sentRequests': sentRequests,
      'receivedRequests': receivedRequests,
      'isPrivate': isPrivate, // Map'e yaz
    };
  }
}

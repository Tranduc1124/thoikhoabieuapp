class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.token,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String token;

  factory AuthSession.fromMap(Map<String, dynamic> data) {
    return AuthSession(
      uid: (data['uid'] ?? data['id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      displayName: (data['displayName'] ?? data['name'] ?? 'Sinh viên')
          .toString(),
      photoURL: (data['photoURL'] ?? data['avatarUrl'])?.toString(),
      token: (data['token'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'token': token,
    };
  }
}

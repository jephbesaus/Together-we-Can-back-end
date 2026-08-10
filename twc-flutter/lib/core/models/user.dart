class User {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? profilePhoto;
  final String? bio;
  final bool isPremium;
  final bool isVerified;
  final int followersCount;
  final int followingCount;
  bool? isFollowing;

  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profilePhoto,
    this.bio,
    required this.isPremium,
    required this.isVerified,
    required this.followersCount,
    required this.followingCount,
    this.isFollowing,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    // Laravel renvoie les id en nombre (int), pas en String : cast sûr avec .toString()
    id: json['id'].toString(),
    name: json['name'] ?? 'Utilisateur',
    email: json['email'],
    phone: json['phone'],
    profilePhoto: json['profile_photo_url'] ?? json['profile_photo'],
    bio: json['bio'],
    isPremium: json['is_premium'] ?? false,
    isVerified: json['is_verified'] ?? false,
    followersCount: json['followers_count'] ?? 0,
    followingCount: json['following_count'] ?? 0,
    isFollowing: json['is_following'],
  );
}

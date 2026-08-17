class Product {
  final String id;
  final String sellerId;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final List<String>? images;
  final String? mainImage;
  final double averageRating;
  final int reviewsCount;
  final bool? isFavorited;
  final DateTime createdAt;
  final String formattedPrice;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.images,
    this.mainImage,
    required this.averageRating,
    required this.reviewsCount,
    this.isFavorited,
    required this.createdAt,
    required this.formattedPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    // Laravel renvoie les id en nombre (int), pas en String : cast sûr avec .toString()
    id: json['id'].toString(),
    sellerId: json['seller_id'].toString(),
    name: json['name'],
    description: json['description'],
    price: double.tryParse('${json['price'] ?? 0}') ?? 0,
    category: json['category'],
    images: json['images'] != null ? List<String>.from(json['images']) : null,
    mainImage: json['main_image'],
    averageRating: double.tryParse('${json['average_rating'] ?? 0}') ?? 0,
    reviewsCount: json['reviews_count'] ?? 0,
    isFavorited: json['is_favorited'],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    formattedPrice: json['formatted_price'] ?? '',
  );
}

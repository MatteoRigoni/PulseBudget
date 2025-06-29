class Category {
  String id;
  String name;
  int iconCodePoint;
  String colorHex;
  String type; // income | expense

  Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorHex,
    required this.type,
  });
}

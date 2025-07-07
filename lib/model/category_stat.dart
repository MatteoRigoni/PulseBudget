class CategoryStat {
  final String categoryId;
  int total;
  Map<String, int> wordCounts;

  CategoryStat({
    required this.categoryId,
    required this.total,
    required this.wordCounts,
  });

  CategoryStat.create({
    required this.categoryId,
    required this.total,
    required this.wordCounts,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'total': total,
      'wordCounts': wordCounts,
    };
  }

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      categoryId: json['categoryId'] as String,
      total: json['total'] as int,
      wordCounts: Map<String, int>.from(json['wordCounts'] as Map),
    );
  }
}

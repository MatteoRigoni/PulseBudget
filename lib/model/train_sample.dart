class TrainSample {
  final int? id;
  final String description;
  final String categoryId;

  TrainSample({
    this.id,
    required this.description,
    required this.categoryId,
  });

  TrainSample.create({
    required this.description,
    required this.categoryId,
  }) : id = null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'categoryId': categoryId,
    };
  }

  factory TrainSample.fromJson(Map<String, dynamic> json) {
    return TrainSample(
      id: json['id'] as int?,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
    );
  }
}

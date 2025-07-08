import 'package:flutter/material.dart';

class Category {
  String id;
  String name;
  IconData icon;
  String colorHex;
  String type; // income | expense
  bool isSeed;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.type,
    this.isSeed = false,
  });

  // Per compatibilità con serializzazione JSON
  int get iconCodePoint => icon.codePoint;

  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xff')));

  // Costruttore da JSON per compatibilità
  Category.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        icon = IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
        colorHex = json['colorHex'],
        type = json['type'],
        isSeed =
            (json['isSeed'] is bool) ? json['isSeed'] : (json['isSeed'] == 1);

  // Metodo per serializzazione JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': icon.codePoint,
        'colorHex': colorHex,
        'type': type,
        'isSeed': isSeed ? 1 : 0, // <-- serializza come int
      };
}

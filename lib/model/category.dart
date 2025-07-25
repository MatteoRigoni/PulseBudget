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

  // Helper function to map code points to constant IconData instances
  static IconData _getIconFromCodePoint(int codePoint) {
    // Map of common Material Icons code points to their constant instances
    switch (codePoint) {
      case 0xe3c3:
        return Icons.work;
      case 0xe8b8:
        return Icons.card_giftcard;
      case 0xe3c4:
        return Icons.shopping_cart;
      case 0xe56c:
        return Icons.restaurant;
      case 0xe88a:
        return Icons.home;
      case 0xe531:
        return Icons.directions_car;
      case 0xe80c:
        return Icons.school;
      case 0xe3c5:
        return Icons.sports_esports;
      case 0xe8b9:
        return Icons.attach_money;
      case 0xe91d:
        return Icons.pets;
      case 0xe548:
        return Icons.local_hospital;
      case 0xe539:
        return Icons.flight;
      case 0xe0cd:
        return Icons.phone;
      case 0xe30a:
        return Icons.computer;
      case 0xe333:
        return Icons.movie;
      case 0xe534:
        return Icons.local_cafe;
      case 0xe540:
        return Icons.local_bar;
      case 0xe43a:
        return Icons.fitness_center;
      case 0xe1b7:
        return Icons.child_care;
      case 0xe533:
        return Icons.local_grocery_store;
      case 0xe89e:
        return Icons.local_offer;
      case 0xe3ca:
        return Icons.beach_access;
      case 0xe02f:
        return Icons.book;
      case 0xe405:
        return Icons.music_note;
      case 0xe8b7:
        return Icons.savings;
      case 0xe59c:
        return Icons.shopping_bag;
      case 0xe8b0:
        return Icons.receipt;
      case 0xe4f4:
        return Icons.spa;
      case 0xe3e3:
        return Icons.healing;
      case 0xe3c5:
        return Icons.park;
      case 0xe3c6:
        return Icons.sports_soccer;
      case 0xe3c7:
        return Icons.sports_basketball;
      case 0xe3c8:
        return Icons.sports_tennis;
      case 0xe3c9:
        return Icons.sports_golf;
      case 0xe3cb:
        return Icons.sports_bar;
      case 0xe3cc:
        return Icons.sports_handball;
      case 0xe3cd:
        return Icons.sports_volleyball;
      case 0xe3ce:
        return Icons.sports_football;
      case 0xe3cf:
        return Icons.sports_rugby;
      case 0xe3d0:
        return Icons.sports_cricket;
      case 0xe3d1:
        return Icons.sports_baseball;
      case 0xe3d2:
        return Icons.sports_hockey;
      case 0xe3d3:
        return Icons.sports;
      case 0xe3d4:
        return Icons.fastfood;
      case 0xe3d5:
        return Icons.icecream;
      case 0xe3d6:
        return Icons.cake;
      case 0xe3d7:
        return Icons.local_pizza;
      case 0xe3d8:
        return Icons.local_dining;
      case 0xe3d9:
        return Icons.emoji_food_beverage;
      case 0xe3da:
        return Icons.emoji_nature;
      case 0xe3db:
        return Icons.emoji_objects;
      case 0xe3dc:
        return Icons.emoji_people;
      case 0xe3dd:
        return Icons.emoji_transportation;
      case 0xe3de:
        return Icons.emoji_events;
      case 0xe3df:
        return Icons.emoji_symbols;
      case 0xe3e0:
        return Icons.emoji_flags;
      case 0xe3e1:
        return Icons.family_restroom;
      case 0xe3e2:
        return Icons.group;
      case 0xe3e4:
        return Icons.person;
      case 0xe3e5:
        return Icons.person_outline;
      case 0xe3e6:
        return Icons.people;
      case 0xe3e7:
        return Icons.pregnant_woman;
      case 0xe3e8:
        return Icons.child_friendly;
      case 0xe3e9:
        return Icons.baby_changing_station;
      case 0xe3ea:
        return Icons.elderly;
      case 0xe3eb:
        return Icons.wc;
      case 0xe3ec:
        return Icons.directions_bike;
      case 0xe3ed:
        return Icons.directions_boat;
      case 0xe3ee:
        return Icons.directions_bus;
      case 0xe3ef:
        return Icons.directions_railway;
      case 0xe3f0:
        return Icons.directions_subway;
      case 0xe3f1:
        return Icons.directions_transit;
      case 0xe3f2:
        return Icons.directions_walk;
      case 0xe3f3:
        return Icons.electric_bike;
      case 0xe3f4:
        return Icons.electric_car;
      case 0xe3f5:
        return Icons.electric_moped;
      case 0xe3f6:
        return Icons.electric_rickshaw;
      case 0xe3f7:
        return Icons.electric_scooter;
      case 0xe3f8:
        return Icons.train;
      case 0xe3f9:
        return Icons.airplanemode_active;
      case 0xe3fa:
        return Icons.airport_shuttle;
      case 0xe3fb:
        return Icons.motorcycle;
      case 0xe3fc:
        return Icons.car_rental;
      case 0xe3fd:
        return Icons.car_repair;
      case 0xe3fe:
        return Icons.local_taxi;
      case 0xe3ff:
        return Icons.local_shipping;
      case 0xe400:
        return Icons.two_wheeler;
      case 0xe401:
        return Icons.pedal_bike;
      case 0xe402:
        return Icons.moped;
      case 0xe403:
        return Icons.subway;
      case 0xe404:
        return Icons.tram;
      case 0xe406:
        return Icons.directions_boat_filled;
      case 0xe407:
        return Icons.sailing;
      case 0xe408:
        return Icons.anchor;
      case 0xe409:
        return Icons.house;
      case 0xe40a:
        return Icons.apartment;
      case 0xe40b:
        return Icons.business;
      case 0xe40c:
        return Icons.cottage;
      case 0xe40d:
        return Icons.villa;
      case 0xe40e:
        return Icons.cabin;
      case 0xe40f:
        return Icons.holiday_village;
      case 0xe410:
        return Icons.domain;
      case 0xe411:
        return Icons.location_city;
      case 0xe412:
        return Icons.location_on;
      case 0xe413:
        return Icons.place;
      case 0xe414:
        return Icons.public;
      case 0xe415:
        return Icons.park;
      case 0xe416:
        return Icons.terrain;
      case 0xe417:
        return Icons.forest;
      case 0xe418:
        return Icons.nature_people;
      case 0xe419:
        return Icons.nature;
      case 0xe41a:
        return Icons.eco;
      case 0xe41b:
        return Icons.wb_sunny;
      case 0xe41c:
        return Icons.nights_stay;
      case 0xe41d:
        return Icons.brightness_2;
      case 0xe41e:
        return Icons.brightness_3;
      case 0xe41f:
        return Icons.brightness_4;
      case 0xe420:
        return Icons.brightness_5;
      case 0xe421:
        return Icons.brightness_6;
      case 0xe422:
        return Icons.brightness_7;
      case 0xe423:
        return Icons.star;
      case 0xe424:
        return Icons.star_border;
      case 0xe425:
        return Icons.star_half;
      case 0xe426:
        return Icons.star_outline;
      case 0xe427:
        return Icons.favorite;
      case 0xe428:
        return Icons.favorite_border;
      case 0xe429:
        return Icons.thumb_up;
      case 0xe42a:
        return Icons.thumb_down;
      case 0xe42b:
        return Icons.check_circle;
      case 0xe42c:
        return Icons.cancel;
      case 0xe42d:
        return Icons.block;
      case 0xe42e:
        return Icons.warning;
      case 0xe42f:
        return Icons.error;
      case 0xe430:
        return Icons.info;
      case 0xe431:
        return Icons.help;
      case 0xe432:
        return Icons.lightbulb;
      case 0xe433:
        return Icons.lightbulb_outline;
      case 0xe434:
        return Icons.flash_on;
      case 0xe435:
        return Icons.flash_off;
      case 0xe436:
        return Icons.bolt;
      case 0xe437:
        return Icons.battery_full;
      case 0xe438:
        return Icons.battery_charging_full;
      case 0xe439:
        return Icons.battery_alert;
      case 0xe43b:
        return Icons.battery_std;
      case 0xe43c:
        return Icons.battery_saver;
      case 0xe43d:
        return Icons.battery_4_bar;
      case 0xe43e:
        return Icons.battery_5_bar;
      case 0xe43f:
        return Icons.battery_6_bar;
      case 0xe440:
        return Icons.battery_0_bar;
      case 0xe441:
        return Icons.battery_1_bar;
      case 0xe442:
        return Icons.battery_2_bar;
      case 0xe443:
        return Icons.battery_3_bar;
      case 0xe8b8:
        return Icons.account_balance;
      case 0xe8b9:
        return Icons.trending_up;
      case 0xe8ba:
        return Icons.checkroom;
      case 0xe8bb:
        return Icons.cleaning_services;
      case 0xe8bc:
        return Icons.local_gas_station;
      case 0xe8bd:
        return Icons.more_horiz;
      case 0xe8be:
        return Icons.category_outlined;
      case 0xe8bf:
        return Icons.credit_card;
      case 0xe8c0:
        return Icons.credit_card_outlined;
      case 0xe8c1:
        return Icons.swap_horiz;
      case 0xe8c2:
        return Icons.attach_money;
      default:
        return Icons.category_outlined;
    }
  }

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

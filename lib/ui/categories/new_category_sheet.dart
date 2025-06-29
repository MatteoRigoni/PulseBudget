import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/categories_provider.dart';
import '../../model/category.dart';

class NewCategorySheet extends ConsumerStatefulWidget {
  final String type;
  final VoidCallback onSaved;

  const NewCategorySheet({
    super.key,
    required this.type,
    required this.onSaved,
  });

  @override
  ConsumerState<NewCategorySheet> createState() => _NewCategorySheetState();
}

class _NewCategorySheetState extends ConsumerState<NewCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedIconCodePoint = 0xe0b8; // Icons.work
  String _selectedColorHex = '#4CAF50';

  final List<int> _availableIcons = [
    Icons.shopping_cart.codePoint,
    Icons.restaurant.codePoint,
    Icons.home.codePoint,
    Icons.directions_car.codePoint,
    Icons.school.codePoint,
    Icons.sports_esports.codePoint,
    Icons.card_giftcard.codePoint,
    Icons.attach_money.codePoint,
    Icons.pets.codePoint,
    Icons.local_hospital.codePoint,
    Icons.flight.codePoint,
    Icons.phone.codePoint,
    Icons.computer.codePoint,
    Icons.movie.codePoint,
    Icons.local_cafe.codePoint,
    Icons.local_bar.codePoint,
    Icons.fitness_center.codePoint,
    Icons.child_care.codePoint,
    Icons.local_grocery_store.codePoint,
    Icons.local_offer.codePoint,
    Icons.beach_access.codePoint,
    Icons.book.codePoint,
    Icons.music_note.codePoint,
    Icons.savings.codePoint,
    Icons.work.codePoint,
    Icons.shopping_bag.codePoint,
    Icons.receipt.codePoint,
    Icons.spa.codePoint,
    Icons.healing.codePoint,
    Icons.park.codePoint,
    Icons.sports_soccer.codePoint,
    Icons.sports_basketball.codePoint,
    Icons.sports_tennis.codePoint,
    Icons.sports_golf.codePoint,
    Icons.sports_motorsports.codePoint,
    Icons.sports_bar.codePoint,
    Icons.sports_handball.codePoint,
    Icons.sports_volleyball.codePoint,
    Icons.sports_football.codePoint,
    Icons.sports_rugby.codePoint,
    Icons.sports_cricket.codePoint,
    Icons.sports_baseball.codePoint,
    Icons.sports_hockey.codePoint,
    Icons.sports.codePoint,
    Icons.fastfood.codePoint,
    Icons.icecream.codePoint,
    Icons.cake.codePoint,
    Icons.local_pizza.codePoint,
    Icons.local_dining.codePoint,
    Icons.emoji_food_beverage.codePoint,
    Icons.emoji_nature.codePoint,
    Icons.emoji_objects.codePoint,
    Icons.emoji_people.codePoint,
    Icons.emoji_transportation.codePoint,
    Icons.emoji_events.codePoint,
    Icons.emoji_symbols.codePoint,
    Icons.emoji_flags.codePoint,
    Icons.family_restroom.codePoint,
    Icons.group.codePoint,
    Icons.groups.codePoint,
    Icons.person.codePoint,
    Icons.person_outline.codePoint,
    Icons.people.codePoint,
    Icons.pregnant_woman.codePoint,
    Icons.child_friendly.codePoint,
    Icons.baby_changing_station.codePoint,
    Icons.elderly.codePoint,
    Icons.wc.codePoint,
    Icons.directions_bike.codePoint,
    Icons.directions_boat.codePoint,
    Icons.directions_bus.codePoint,
    Icons.directions_railway.codePoint,
    Icons.directions_subway.codePoint,
    Icons.directions_transit.codePoint,
    Icons.directions_walk.codePoint,
    Icons.electric_bike.codePoint,
    Icons.electric_car.codePoint,
    Icons.electric_moped.codePoint,
    Icons.electric_rickshaw.codePoint,
    Icons.electric_scooter.codePoint,
    Icons.train.codePoint,
    Icons.airplanemode_active.codePoint,
    Icons.airport_shuttle.codePoint,
    Icons.motorcycle.codePoint,
    Icons.car_rental.codePoint,
    Icons.car_repair.codePoint,
    Icons.local_taxi.codePoint,
    Icons.local_shipping.codePoint,
    Icons.two_wheeler.codePoint,
    Icons.pedal_bike.codePoint,
    Icons.moped.codePoint,
    Icons.subway.codePoint,
    Icons.tram.codePoint,
    Icons.directions_ferry.codePoint,
    Icons.directions_boat_filled.codePoint,
    Icons.sailing.codePoint,
    Icons.anchor.codePoint,
    Icons.house.codePoint,
    Icons.apartment.codePoint,
    Icons.business.codePoint,
    Icons.cottage.codePoint,
    Icons.villa.codePoint,
    Icons.cabin.codePoint,
    Icons.holiday_village.codePoint,
    Icons.domain.codePoint,
    Icons.location_city.codePoint,
    Icons.location_on.codePoint,
    Icons.place.codePoint,
    Icons.public.codePoint,
    Icons.park.codePoint,
    Icons.terrain.codePoint,
    Icons.forest.codePoint,
    Icons.nature_people.codePoint,
    Icons.nature.codePoint,
    Icons.eco.codePoint,
    Icons.wb_sunny.codePoint,
    Icons.nights_stay.codePoint,
    Icons.brightness_2.codePoint,
    Icons.brightness_3.codePoint,
    Icons.brightness_4.codePoint,
    Icons.brightness_5.codePoint,
    Icons.brightness_6.codePoint,
    Icons.brightness_7.codePoint,
    Icons.star.codePoint,
    Icons.star_border.codePoint,
    Icons.star_half.codePoint,
    Icons.star_outline.codePoint,
    Icons.favorite.codePoint,
    Icons.favorite_border.codePoint,
    Icons.thumb_up.codePoint,
    Icons.thumb_down.codePoint,
    Icons.check_circle.codePoint,
    Icons.cancel.codePoint,
    Icons.block.codePoint,
    Icons.warning.codePoint,
    Icons.error.codePoint,
    Icons.info.codePoint,
    Icons.help.codePoint,
    Icons.lightbulb.codePoint,
    Icons.lightbulb_outline.codePoint,
    Icons.flash_on.codePoint,
    Icons.flash_off.codePoint,
    Icons.bolt.codePoint,
    Icons.battery_full.codePoint,
    Icons.battery_charging_full.codePoint,
    Icons.battery_alert.codePoint,
    Icons.battery_unknown.codePoint,
    Icons.battery_std.codePoint,
    Icons.battery_saver.codePoint,
    Icons.battery_4_bar.codePoint,
    Icons.battery_5_bar.codePoint,
    Icons.battery_6_bar.codePoint,
    Icons.battery_0_bar.codePoint,
    Icons.battery_1_bar.codePoint,
    Icons.battery_2_bar.codePoint,
    Icons.battery_3_bar.codePoint,
  ];

  final List<String> _availableColors = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#E91E63', // Pink
    '#FF5722', // Deep Orange
    '#607D8B', // Blue Grey
    '#9C27B0', // Purple
    '#F44336', // Red
    '#673AB7', // Deep Purple
    '#00BCD4', // Cyan
    '#795548', // Brown
    '#8BC34A', // Light Green
    '#FFC107', // Amber
    '#3F51B5', // Indigo
    '#009688', // Teal
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final category = Category(
        id: '${widget.type}-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        iconCodePoint: _selectedIconCodePoint,
        colorHex: _selectedColorHex,
        type: widget.type,
      );

      ref.read(categoriesProvider.notifier).addCategory(category);
      widget.onSaved();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Nuova categoria',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annulla'),
                      ),
                      FilledButton(
                        onPressed: _saveCategory,
                        child: const Text('Salva'),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome categoria
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome categoria',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci un nome per la categoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Icona
                        Text(
                          'Icona',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _availableIcons.length,
                            itemBuilder: (context, index) {
                              final iconCodePoint = _availableIcons[index];
                              final isSelected =
                                  iconCodePoint == _selectedIconCodePoint;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIconCodePoint = iconCodePoint;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                            .withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 2)
                                        : null,
                                  ),
                                  child: Icon(
                                    IconData(iconCodePoint,
                                        fontFamily: 'MaterialIcons'),
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Colore
                        Text(
                          'Colore',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableColors.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final colorHex = _availableColors[index];
                              final color = Color(
                                  int.parse(colorHex.replaceAll('#', '0xFF')));
                              final isSelected = colorHex == _selectedColorHex;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedColorHex = colorHex;
                                  });
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white, width: 3)
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 24)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

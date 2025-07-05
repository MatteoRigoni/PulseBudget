import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/categories_provider.dart';
import '../../model/category.dart';
import 'package:uuid/uuid.dart';

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
  IconData _selectedIcon = Icons.work;
  String _selectedColorHex = '#4CAF50';

  final List<IconData> _availableIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.home,
    Icons.directions_car,
    Icons.school,
    Icons.sports_esports,
    Icons.card_giftcard,
    Icons.attach_money,
    Icons.pets,
    Icons.local_hospital,
    Icons.flight,
    Icons.phone,
    Icons.computer,
    Icons.movie,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.fitness_center,
    Icons.child_care,
    Icons.local_grocery_store,
    Icons.local_offer,
    Icons.beach_access,
    Icons.book,
    Icons.music_note,
    Icons.savings,
    Icons.work,
    Icons.shopping_bag,
    Icons.receipt,
    Icons.spa,
    Icons.healing,
    Icons.park,
    Icons.sports_soccer,
    Icons.sports_basketball,
    Icons.sports_tennis,
    Icons.sports_golf,
    Icons.sports_motorsports,
    Icons.sports_bar,
    Icons.sports_handball,
    Icons.sports_volleyball,
    Icons.sports_football,
    Icons.sports_rugby,
    Icons.sports_cricket,
    Icons.sports_baseball,
    Icons.sports_hockey,
    Icons.sports,
    Icons.fastfood,
    Icons.icecream,
    Icons.cake,
    Icons.local_pizza,
    Icons.local_dining,
    Icons.emoji_food_beverage,
    Icons.emoji_nature,
    Icons.emoji_objects,
    Icons.emoji_people,
    Icons.emoji_transportation,
    Icons.emoji_events,
    Icons.emoji_symbols,
    Icons.emoji_flags,
    Icons.family_restroom,
    Icons.group,
    Icons.groups,
    Icons.person,
    Icons.person_outline,
    Icons.people,
    Icons.pregnant_woman,
    Icons.child_friendly,
    Icons.baby_changing_station,
    Icons.elderly,
    Icons.wc,
    Icons.directions_bike,
    Icons.directions_boat,
    Icons.directions_bus,
    Icons.directions_railway,
    Icons.directions_subway,
    Icons.directions_transit,
    Icons.directions_walk,
    Icons.electric_bike,
    Icons.electric_car,
    Icons.electric_moped,
    Icons.electric_rickshaw,
    Icons.electric_scooter,
    Icons.train,
    Icons.airplanemode_active,
    Icons.airport_shuttle,
    Icons.motorcycle,
    Icons.car_rental,
    Icons.car_repair,
    Icons.local_taxi,
    Icons.local_shipping,
    Icons.two_wheeler,
    Icons.pedal_bike,
    Icons.moped,
    Icons.subway,
    Icons.tram,
    Icons.directions_ferry,
    Icons.directions_boat_filled,
    Icons.sailing,
    Icons.anchor,
    Icons.house,
    Icons.apartment,
    Icons.business,
    Icons.cottage,
    Icons.villa,
    Icons.cabin,
    Icons.holiday_village,
    Icons.domain,
    Icons.location_city,
    Icons.location_on,
    Icons.place,
    Icons.public,
    Icons.park,
    Icons.terrain,
    Icons.forest,
    Icons.nature_people,
    Icons.nature,
    Icons.eco,
    Icons.wb_sunny,
    Icons.nights_stay,
    Icons.brightness_2,
    Icons.brightness_3,
    Icons.brightness_4,
    Icons.brightness_5,
    Icons.brightness_6,
    Icons.brightness_7,
    Icons.star,
    Icons.star_border,
    Icons.star_half,
    Icons.star_outline,
    Icons.favorite,
    Icons.favorite_border,
    Icons.thumb_up,
    Icons.thumb_down,
    Icons.check_circle,
    Icons.cancel,
    Icons.block,
    Icons.warning,
    Icons.error,
    Icons.info,
    Icons.help,
    Icons.lightbulb,
    Icons.lightbulb_outline,
    Icons.flash_on,
    Icons.flash_off,
    Icons.bolt,
    Icons.battery_full,
    Icons.battery_charging_full,
    Icons.battery_alert,
    Icons.battery_unknown,
    Icons.battery_std,
    Icons.battery_saver,
    Icons.battery_4_bar,
    Icons.battery_5_bar,
    Icons.battery_6_bar,
    Icons.battery_0_bar,
    Icons.battery_1_bar,
    Icons.battery_2_bar,
    Icons.battery_3_bar,
  ];

  final List<String> _availableColors = [
    '#F44336', // Red
    '#E91E63', // Pink
    '#FF9800', // Orange
    '#FFEB3B', // Yellow
    '#4CAF50', // Green
    '#00BCD4', // Cyan
    '#2196F3', // Blue
    '#3F51B5', // Indigo
    '#9C27B0', // Purple
    '#FFC107', // Amber
    '#FF5722', // Deep Orange
    '#009688', // Teal
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final category = Category(
        id: '${widget.type}-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        colorHex: _selectedColorHex,
        type: widget.type,
      );

      await ref.read(categoriesNotifierProvider.notifier).add(category);
      widget.onSaved();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                        onPressed: () async => await _saveCategory(),
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
                          decoration: InputDecoration(
                            labelText: 'Nome categoria',
                            border: const OutlineInputBorder(),
                            fillColor: theme.colorScheme.surface,
                            filled: true,
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
                              final icon = _availableIcons[index];
                              final isSelected = icon == _selectedIcon;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIcon = icon;
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
                                    icon,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../model/snapshot.dart';
import '../../providers/snapshot_provider.dart';
import 'package:collection/collection.dart';
import '../home/home_screen.dart';

class NewSnapshotSheet extends ConsumerStatefulWidget {
  const NewSnapshotSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<NewSnapshotSheet> createState() => _NewSnapshotSheetState();
}

class _NewSnapshotSheetState extends ConsumerState<NewSnapshotSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEntityId;
  double? _amount;
  DateTime _date = DateTime.now();
  String? _note;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Imposta come default l'entità selezionata nel filtro
    final selectedEntity = WidgetsBinding.instance != null
        ? WidgetsBinding.instance!.addPostFrameCallback((_) {
            final id = ref.read(selectedEntityProvider);
            setState(() {
              _selectedEntityId = id;
            });
          })
        : null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final entities = ref.watch(entityProvider);
    final entityNotifier = ref.read(entityProvider.notifier);
    return FractionallySizedBox(
      heightFactor: 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: mq.viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nuova rilevazione',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedEntityId ??
                            (entities.isNotEmpty ? entities.first.id : null),
                        decoration: InputDecoration(
                          labelText: 'Account',
                          labelStyle: Theme.of(context).textTheme.bodyMedium,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final e in entities)
                            DropdownMenuItem(
                              value: e.id,
                              child: Text('${e.type.toUpperCase()} (${e.name})',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ),
                        ],
                        onChanged: (v) => setState(() => _selectedEntityId = v),
                        validator: (v) =>
                            v == null ? 'Seleziona un account' : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Aggiungi account',
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () async {
                        String? type;
                        String? name;
                        await showDialog(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: const Text('Nuovo account'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Tipologia',
                                      labelStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'Conto', child: Text('Conto')),
                                      DropdownMenuItem(
                                          value: 'Dossier',
                                          child: Text('Dossier')),
                                      DropdownMenuItem(
                                          value: 'Altro', child: Text('Altro')),
                                    ],
                                    onChanged: (v) => type = v,
                                  ),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Nome',
                                      labelStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => name = v,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text('Annulla',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (type != null &&
                                        name != null &&
                                        name!.trim().isNotEmpty) {
                                      entityNotifier.addEntity(
                                          type!, name!.trim());
                                      setState(() => _selectedEntityId =
                                          ref.read(entityProvider).last.id);
                                      Navigator.of(ctx).pop();
                                    }
                                  },
                                  child: Text('Salva',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('it', 'IT'),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _date = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                          );
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Data',
                        border: OutlineInputBorder(),
                        fillColor: Theme.of(context).colorScheme.surface,
                        filled: true,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Importo',
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                    prefixText: '€ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = double.tryParse(v!.replaceAll(',', '.'));
                    if (value == null || value <= 0)
                      return 'Importo non valido';
                    return null;
                  },
                  onSaved: (v) =>
                      _amount = double.tryParse(v!.replaceAll(',', '.')),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (facoltative)',
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                  onSaved: (v) => _note = v,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            final entity = entities.firstWhereOrNull(
                                (e) => e.id == _selectedEntityId);
                            if (entity == null) return;
                            final snapshot = Snapshot(
                              id: const Uuid().v4(),
                              date: _date,
                              label: entity.name,
                              amount: _amount!,
                              note: _noteController.text.isNotEmpty
                                  ? _noteController.text
                                  : null,
                            );
                            await ref
                                .read(snapshotNotifierProvider.notifier)
                                .add(snapshot);
                            Navigator.of(context).pop();
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text('Salva'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

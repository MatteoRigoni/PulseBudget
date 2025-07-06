import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'snapshot_card.dart';
import 'package:collection/collection.dart';
import '../../model/snapshot.dart';
import '../../providers/snapshot_provider.dart';
import 'new_snapshot_sheet.dart';
import '../widgets/app_title_widget.dart';

class PatrimonioScreen extends ConsumerWidget {
  const PatrimonioScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entities = ref.watch(entityProvider);
    final selectedEntityId = ref.watch(selectedEntityProvider);
    final snapshotsAsync = ref.watch(snapshotProvider);

    // Gestisci stati di loading e error
    if (snapshotsAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshotsAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Errore nel caricamento: ${snapshotsAsync.error}'),
            ],
          ),
        ),
      );
    }

    final snapshots = snapshotsAsync.value ?? [];
    final filteredSnapshots = snapshots
        .where((s) =>
            s.label ==
            (entities.firstWhereOrNull((e) => e.id == selectedEntityId)?.name ??
                ''))
        .toList();

    final entityNotifier = ref.read(entityProvider.notifier);
    final setSelectedEntity = ref.read(selectedEntityProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const AppTitleWidget(title: 'Patrimonio'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              // TODO: Implementare ordinamento con Firestore
              if (value == 'date') {
                // notifier.sortByDateDesc();
              } else if (value == 'amount') {
                // notifier.sortByAmountDesc();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Ordina per data'),
              ),
              const PopupMenuItem(
                value: 'amount',
                child: Text('Ordina per valore'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro account
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: entities.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i < entities.length) {
                  final entity = entities[i];
                  return GestureDetector(
                    onLongPress: () {
                      if (entities.length > 1) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Elimina account?'),
                            content: Text(
                                'Vuoi eliminare ${entity.type} ${entity.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Annulla'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await entityNotifier.removeEntity(entity.id);
                                  if (selectedEntityId == entity.id &&
                                      entities.length > 1) {
                                    setSelectedEntity.state = entities
                                        .firstWhere((e) => e.id != entity.id)
                                        .id;
                                  }
                                  Navigator.of(ctx).pop();
                                },
                                child: const Text('Elimina'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: ChoiceChip(
                      label: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: entity.type.toUpperCase(),
                              style: TextStyle(
                                color: selectedEntityId == entity.id
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '  ',
                            ),
                            TextSpan(
                              text: '(${entity.name})',
                              style: TextStyle(
                                color: selectedEntityId == entity.id
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.85)
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                          style: DefaultTextStyle.of(context).style,
                        ),
                      ),
                      selected: selectedEntityId == entity.id,
                      onSelected: (_) => setSelectedEntity.state = entity.id,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: selectedEntityId == entity.id
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                } else {
                  // Bottone aggiungi account
                  return ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Aggiungi account'),
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
                                  decoration: const InputDecoration(
                                      labelText: 'Tipologia account'),
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
                                  decoration:
                                      const InputDecoration(labelText: 'Nome'),
                                  onChanged: (v) => name = v,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Annulla'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (type != null &&
                                      name != null &&
                                      name!.trim().isNotEmpty) {
                                    final normalized =
                                        (String s) => s.trim().toLowerCase();
                                    final exists = ref.read(entityProvider).any(
                                        (e) =>
                                            normalized(e.type) ==
                                                normalized(type!) &&
                                            normalized(e.name) ==
                                                normalized(name!));
                                    if (exists) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Account già esistente con stesso tipo e nome')),
                                      );
                                    } else {
                                      await entityNotifier.addEntity(
                                          type!, name!.trim());
                                      try {
                                        setSelectedEntity.state =
                                            ref.read(entityProvider).last.id;
                                      } catch (_) {}
                                      Navigator.of(ctx).pop();
                                    }
                                  }
                                },
                                child: const Text('Salva'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
          Expanded(
            child: snapshots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 64, color: Colors.amber.shade400),
                        const SizedBox(height: 16),
                        Text('Nessuna rilevazione presente!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: snapshots.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.7,
                      color: Theme.of(context).dividerColor.withOpacity(0.7),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final snapshot = snapshots[index];
                      final prev = snapshots.skip(index + 1).firstWhereOrNull(
                            (s) => s.label == snapshot.label,
                          );
                      return Dismissible(
                        key: ValueKey(snapshot.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Elimina',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Elimina',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.delete, color: Colors.white),
                            ],
                          ),
                        ),
                        onDismissed: (direction) async {
                          await ref
                              .read(snapshotNotifierProvider.notifier)
                              .remove(snapshot.id);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Rilevazione eliminata'),
                              action: SnackBarAction(
                                label: 'Ripristina',
                                onPressed: () async {
                                  // TODO: Implementare undo con Firestore
                                },
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        child: SnapshotCard(
                          snapshot: snapshot,
                          previous: prev,
                          onDelete: () async {
                            await ref
                                .read(snapshotNotifierProvider.notifier)
                                .remove(snapshot.id);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Rilevazione eliminata'),
                                action: SnackBarAction(
                                  label: 'Ripristina',
                                  onPressed: () async {
                                    // TODO: Implementare undo con Firestore
                                  },
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FilledButton.icon(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const NewSnapshotSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuova rilevazione'),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: Theme.of(context).textTheme.labelLarge,
          elevation: 8,
        ),
      ),
    );
  }
}

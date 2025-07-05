import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/snapshot.dart';
import '../repository/balance_repository.dart';
import 'repository_providers.dart';
import 'dart:collection';
import 'package:uuid/uuid.dart';

/// Provider per tutti gli snapshot (StreamProvider)
final snapshotProvider = StreamProvider<List<Snapshot>>((ref) {
  final repository = ref.watch(balanceRepositoryProvider);
  return repository.watchAll();
});

/// Provider per gli snapshot filtrati per periodo
final snapshotsByPeriodProvider =
    StreamProvider.family<List<Snapshot>, ({DateTime start, DateTime end})>(
        (ref, period) {
  final repository = ref.watch(balanceRepositoryProvider);
  return repository.watchByPeriod(period.start, period.end);
});

/// Notifier per le operazioni CRUD degli snapshot
class SnapshotNotifier extends StateNotifier<AsyncValue<void>> {
  final BalanceRepository _repository;

  SnapshotNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> add(Snapshot snapshot) async {
    state = const AsyncValue.loading();
    try {
      await _repository.add(snapshot);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> remove(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> update(Snapshot snapshot) async {
    state = const AsyncValue.loading();
    try {
      await _repository.update(snapshot);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addBatch(List<Snapshot> snapshots) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBatch(snapshots);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider per le operazioni CRUD degli snapshot
final snapshotNotifierProvider =
    StateNotifierProvider<SnapshotNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(balanceRepositoryProvider);
  return SnapshotNotifier(repository);
});

// Provider per le entità (mantenuto come prima per ora)
class EntityNotifier extends StateNotifier<List<Entity>> {
  EntityNotifier() : super([]);

  void addEntity(String type, String name) {
    final normalized = (String s) => s.trim().toLowerCase();
    final exists = state.any((e) =>
        normalized(e.type) == normalized(type) &&
        normalized(e.name) == normalized(name));
    if (exists) return;
    state = [
      ...state,
      Entity(id: const Uuid().v4(), type: type, name: name),
    ];
  }

  void removeEntity(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}

final entityProvider = StateNotifierProvider<EntityNotifier, List<Entity>>(
    (ref) => EntityNotifier());

final selectedEntityProvider = StateProvider<String?>((ref) {
  final entities = ref.watch(entityProvider);
  return entities.isNotEmpty ? entities.first.id : null;
});

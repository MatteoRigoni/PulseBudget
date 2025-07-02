import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/snapshot.dart';
import 'dart:collection';
import 'package:uuid/uuid.dart';

class SnapshotNotifier extends StateNotifier<List<Snapshot>> {
  SnapshotNotifier() : super([]);

  Snapshot? _lastRemoved;
  int? _lastRemovedIndex;

  void add(Snapshot snapshot) {
    state = [...state, snapshot]..sort((a, b) => b.date.compareTo(a.date));
  }

  void remove(String id) {
    _lastRemovedIndex = state.indexWhere((s) => s.id == id);
    if (_lastRemovedIndex != null && _lastRemovedIndex! >= 0) {
      _lastRemoved = state[_lastRemovedIndex!];
      final newList = [...state]..removeAt(_lastRemovedIndex!);
      state = newList;
    }
  }

  void undoRemove() {
    if (_lastRemoved != null && _lastRemovedIndex != null) {
      final newList = [...state];
      newList.insert(_lastRemovedIndex!, _lastRemoved!);
      state = newList;
      _lastRemoved = null;
      _lastRemovedIndex = null;
    }
  }

  void sortByDateDesc() {
    state = [...state]..sort((a, b) => b.date.compareTo(a.date));
  }

  void sortByAmountDesc() {
    state = [...state]..sort((a, b) => b.amount.compareTo(a.amount));
  }
}

final snapshotProvider =
    StateNotifierProvider<SnapshotNotifier, List<Snapshot>>(
        (ref) => SnapshotNotifier());

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

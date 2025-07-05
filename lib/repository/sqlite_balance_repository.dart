import 'dart:async';
import 'balance_repository.dart';
import '../model/snapshot.dart';
import '../services/database_service.dart';

class SqliteBalanceRepository implements BalanceRepository {
  final DatabaseService _databaseService;
  final StreamController<List<Snapshot>> _snapshotsController =
      StreamController<List<Snapshot>>.broadcast();

  SqliteBalanceRepository(this._databaseService) {
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    try {
      final snapshots = await _databaseService.getSnapshots();
      _snapshotsController.add(snapshots);
    } catch (e) {
      _snapshotsController.addError(e);
    }
  }

  @override
  Stream<List<Snapshot>> watchAll() {
    return _snapshotsController.stream;
  }

  @override
  Stream<List<Snapshot>> watchByPeriod(DateTime start, DateTime end) {
    return _snapshotsController.stream.map((snapshots) {
      return snapshots.where((snapshot) {
        return snapshot.date.isAfter(start.subtract(const Duration(days: 1))) &&
            snapshot.date.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    });
  }

  @override
  Future<Snapshot?> getById(String id) async {
    final snapshots = await _databaseService.getSnapshots();
    try {
      return snapshots.firstWhere((snapshot) => snapshot.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(Snapshot snapshot) async {
    await _databaseService.insertSnapshot(snapshot);
    await _loadSnapshots();
  }

  @override
  Future<void> update(Snapshot snapshot) async {
    await _databaseService.updateSnapshot(snapshot);
    await _loadSnapshots();
  }

  @override
  Future<void> delete(String id) async {
    await _databaseService.deleteSnapshot(id);
    await _loadSnapshots();
  }

  @override
  Future<void> addBatch(List<Snapshot> snapshots) async {
    for (final snapshot in snapshots) {
      await _databaseService.insertSnapshot(snapshot);
    }
    await _loadSnapshots();
  }

  void dispose() {
    _snapshotsController.close();
  }
}

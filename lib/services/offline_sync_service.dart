import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_helper.dart';
import 'equipment_operation_service.dart';

class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._init();
  
  OfflineSyncService._init();

  final _connectivity = Connectivity();
  final _dbHelper = DatabaseHelper.instance;
  final _service = EquipmentOperationService();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  // Start listening to connectivity changes
  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _onConnectivityChanged(results);
    });
    
    // Check initial connectivity and sync if online
    _checkAndSync();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );

    if (isOnline && !_isSyncing) {
      print('OfflineSync: Device is online, starting sync...');
      syncPendingTasks();
    }
  }

  Future<void> _checkAndSync() async {
    final results = await _connectivity.checkConnectivity();
    _onConnectivityChanged(results);
  }

  // Sync all pending tasks
  Future<void> syncPendingTasks() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      final pendingTasks = await _dbHelper.getPendingTasks();
      
      if (pendingTasks.isEmpty) {
        print('OfflineSync: No pending tasks to sync');
        return;
      }

      print('OfflineSync: Found ${pendingTasks.length} pending tasks');

      for (final task in pendingTasks) {
        final id = task['id'] as int;
        final operationScrum = task['operation_scrum'] as String;
        final taskDataJson = task['task_data'] as String;
        final taskData = jsonDecode(taskDataJson) as Map<String, dynamic>;

        try {
          // Attempt to create the task
          await _service.createTask(operationScrum, taskData);
          
          // Success - delete from queue
          await _dbHelper.deletePendingTask(id);
          print('OfflineSync: Successfully synced task $id');
        } catch (e) {
          // Failed - increment retry count
          await _dbHelper.incrementRetryCount(id);
          print('OfflineSync: Failed to sync task $id: $e');
          
          // Stop syncing if we hit an error (might be auth issue, etc.)
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  // Get count of pending tasks for an operation
  Future<int> getPendingCount(String operationScrum) async {
    return await _dbHelper.getPendingTasksCount(operationScrum);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

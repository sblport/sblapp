import 'package:flutter/foundation.dart';
import '../models/equipment_operation.dart';
import '../models/equipment.dart';
import '../models/activity.dart';
import '../models/location.dart';
import '../models/equipment_operation_requests.dart';
import '../services/equipment_operation_service.dart';

class EquipmentOperationProvider with ChangeNotifier {
  final EquipmentOperationService _service = EquipmentOperationService();

  // Operations list state
  List<EquipmentOperation> _operations = [];
  bool _isLoadingOperations = false;
  String? _operationsError;
  int _currentPage = 1;
  int _lastPage = 1;

  // Single operation state
  EquipmentOperation? _currentOperation;
  bool _isLoadingOperation = false;
  String? _operationError;

  // Reference data
  List<Equipment> _equipment = [];
  List<Activity> _activities = [];
  List<Location> _locations = [];
  bool _isLoadingReferenceData = false;

  // Filters
  Equipment? _filterEquipment;
  DateTime? _filterDate;

  // Getters
  List<EquipmentOperation> get operations => _operations;
  bool get isLoadingOperations => _isLoadingOperations;
  String? get operationsError => _operationsError;
  bool get hasMorePages => _currentPage < _lastPage;

  EquipmentOperation? get currentOperation => _currentOperation;
  bool get isLoadingOperation => _isLoadingOperation;
  String? get operationError => _operationError;

  List<Equipment> get equipment => _equipment;
  List<Activity> get activities => _activities;
  List<Location> get locations => _locations;
  bool get isLoadingReferenceData => _isLoadingReferenceData;

  Equipment? get filterEquipment => _filterEquipment;
  DateTime? get filterDate => _filterDate;

  void setFilters({Equipment? equipment, DateTime? date}) {
    _filterEquipment = equipment;
    _filterDate = date;
    loadOperations(refresh: true);
  }

  void clearFilters() {
    _filterEquipment = null;
    _filterDate = null;
    loadOperations(refresh: true);
  }


  /// Load operations list
  Future<void> loadOperations({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _operations.clear();
    }

    _isLoadingOperations = true;
    _operationsError = null;
    notifyListeners();

    try {
      final response = await _service.getOperations(
        page: _currentPage,
        equipmentId: _filterEquipment?.id,
        startDate: _filterDate,
        endDate: _filterDate,
      );
      
      if (refresh) {
        _operations = response.data;
      } else {
        _operations.addAll(response.data);
      }
      
      _currentPage = response.currentPage;
      _lastPage = response.lastPage;
      _operationsError = null;
    } catch (e) {
      _operationsError = e.toString();
    } finally {
      _isLoadingOperations = false;
      notifyListeners();
    }
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (!hasMorePages || _isLoadingOperations) return;
    _currentPage++;
    await loadOperations();
  }

  /// Load single operation
  Future<void> loadOperation(String scrum) async {
    _isLoadingOperation = true;
    _operationError = null;
    notifyListeners();

    try {
      _currentOperation = await _service.getOperation(scrum);
      _operationError = null;
    } catch (e) {
      _operationError = e.toString();
    } finally {
      _isLoadingOperation = false;
      notifyListeners();
    }
  }

  /// Create operation
  Future<EquipmentOperation?> createOperation(CreateOperationRequest request) async {
    _isLoadingOperation = true;
    _operationError = null;
    notifyListeners();

    try {
      final operation = await _service.createOperation(request);
      // We should insert it into the list locally so the user sees it immediately if they go back
      _operations.insert(0, operation); 
      return operation;
    } catch (e) {
      _operationError = e.toString();
      return null;
    } finally {
      _isLoadingOperation = false;
      notifyListeners();
    }
  }

  /// Add task to current operation
  Future<bool> addTask(String scrum, CreateTaskRequest request) async {
    try {
      final task = await _service.addTask(scrum, request);
      
      if (task == null) {
        // Task was saved offline, return false to indicate offline save
        return false;
      }
      
      // Update current operation if it's loaded
      if (_currentOperation != null && _currentOperation!.scrum == scrum) {
        // Reload the operation to get fresh data
        await loadOperation(scrum);
      }
      
      return true; // Successfully added online
    } catch (e) {
      rethrow;
    }
  }

  /// Finish operation
  Future<bool> finishOperation(
    String scrum,
    FinishOperationRequest request, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final operation = await _service.finishOperation(
        scrum,
        request,
        onProgress: onProgress,
      );
      
      // Update in operations list
      final index = _operations.indexWhere((op) => op.scrum == scrum);
      if (index != -1) {
        _operations[index] = operation;
      }
      
      // Update current operation
      if (_currentOperation != null && _currentOperation!.scrum == scrum) {
        _currentOperation = operation;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load all reference data
  Future<void> loadReferenceData() async {
    // Force reload to ensure we get data
    // if (_equipment.isNotEmpty) return; 

    _isLoadingReferenceData = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getEquipment(),
        _service.getActivities(),
        _service.getLocations(),
      ]);

      if (results.length >= 3) {
        _equipment = results[0] as List<Equipment>;
        _activities = results[1] as List<Activity>;
        _locations = results[2] as List<Location>;
      }
    } catch (e) {
      print('Failed to load reference data: $e');
      // Set empty lists on error
      _equipment = [];
      _activities = [];
      _locations = [];
    } finally {
      _isLoadingReferenceData = false;
      notifyListeners();
    }
  }

  /// Clear current operation
  void clearCurrentOperation() {
    _currentOperation = null;
    notifyListeners();
  }
}

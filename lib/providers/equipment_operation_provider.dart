import 'package:flutter/foundation.dart';
import '../models/equipment_operation.dart';
import '../models/equipment.dart';
import '../models/activity.dart';
import '../models/location.dart';
import '../models/organization.dart';
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
  List<Organization> _organizations = [];
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
  List<Organization> get organizations => _organizations;
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

  /// Delete task
  Future<bool> deleteTask(String scrum, String taskId) async {
    try {
      await _service.deleteTask(scrum, taskId);
      
      // Update current operation by removing the task locally to update UI immediately
      if (_currentOperation != null && _currentOperation!.scrum == scrum) {
        // We have to reload to be safe or mutable remove
        await loadOperation(scrum);
      }
      return true;
    } catch (e) {
      _operationError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Approve operation
  Future<bool> approveOperation(String scrum) async {
    _isLoadingOperation = true;
    notifyListeners();
    try {
      final operation = await _service.approveOperation(scrum);
      
      // Update in operations list
      final index = _operations.indexWhere((op) => op.scrum == scrum);
      if (index != -1) {
        _operations[index] = operation;
      }
      
      if (_currentOperation != null && _currentOperation!.scrum == scrum) {
        _currentOperation = operation;
      }
      
      return true;
    } catch (e) {
      _operationError = e.toString();
      return false;
    } finally {
      _isLoadingOperation = false;
      notifyListeners();
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
        // Reload entirely to ensure all relationships (tasks, etc.) are present
        // The returned operation object might miss some nested data depending on API
        await loadOperation(scrum);
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
    _isLoadingReferenceData = true;
    notifyListeners();

    try {
      print('DEBUG: Loading reference data...');
      
      try {
        _equipment = await _service.getEquipment();
        print('DEBUG: Equipment loaded: ${_equipment.length}');
      } catch (e) { 
        print('DEBUG: Failed to load equipment: $e'); 
        _equipment = [];
      }

      try {
        _activities = await _service.getActivities();
        print('DEBUG: Activities loaded: ${_activities.length}');
      } catch (e) { 
        print('DEBUG: Failed to load activities: $e'); 
        _activities = [];
      }

      try {
        _locations = await _service.getLocations();
        print('DEBUG: Locations loaded: ${_locations.length}');
      } catch (e) { 
        print('DEBUG: Failed to load locations: $e'); 
        _locations = [];
      }

      try {
        _organizations = await _service.getOrganizations();
        print('DEBUG: Organizations loaded: ${_organizations.length}');
      } catch (e) { 
        print('DEBUG: Failed to load organizations: $e'); 
        _organizations = [];
      }

    } catch (e) {
      print('DEBUG: Fatal error in loadReferenceData: $e');
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

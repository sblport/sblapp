import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/equipment_operation.dart';
import '../models/equipment.dart';
import '../models/activity.dart';
import '../models/location.dart';
import '../models/task.dart';
import '../models/equipment_operation_requests.dart';

class EquipmentOperationService {
  final Dio _dio;

  EquipmentOperationService() : _dio = Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle errors globally
        print('API Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  /// Get paginated list of operations
  Future<PaginatedResponse<EquipmentOperation>> getOperations(int page) async {
    try {
      final response = await _dio.get(
        ApiConstants.eqpOperationsEndpoint,
        queryParameters: {'page': page},
      );

      final data = response.data['data'] as List;
      final operations = data.map((json) => EquipmentOperation.fromJson(json)).toList();

      return PaginatedResponse(
        data: operations,
        currentPage: int.tryParse(response.data['current_page'].toString()) ?? 1,
        lastPage: int.tryParse(response.data['last_page'].toString()) ?? 1,
        perPage: int.tryParse(response.data['per_page'].toString()) ?? 20,
        total: int.tryParse(response.data['total'].toString()) ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to load operations: $e');
    }
  }

  /// Get single operation by scrum ID
  Future<EquipmentOperation> getOperation(String scrum) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.eqpOperationsEndpoint}/$scrum',
      );

      return EquipmentOperation.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load operation: $e');
    }
  }

  /// Create new operation
  Future<EquipmentOperation> createOperation(CreateOperationRequest request) async {
    try {
      final formData = FormData.fromMap({
        ...request.toMap(),
        'photo': await MultipartFile.fromFile(
          request.photo.path,
          filename: request.photo.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        ApiConstants.eqpOperationsEndpoint,
        data: formData,
      );

      return EquipmentOperation.fromJson(response.data['operation']);
    } catch (e) {
      throw Exception('Failed to create operation: $e');
    }
  }

  /// Add task to operation
  Future<Task> addTask(String scrum, CreateTaskRequest request) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.eqpOperationsEndpoint}/$scrum/tasks',
        data: request.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      return Task.fromJson(response.data['task']);
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  /// Finish operation
  Future<EquipmentOperation> finishOperation(
    String scrum,
    FinishOperationRequest request,
  ) async {
    try {
      final formData = FormData.fromMap({
        ...request.toMap(),
        'photo2': await MultipartFile.fromFile(
          request.photo2.path,
          filename: request.photo2.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '${ApiConstants.eqpOperationsEndpoint}/$scrum/finish',
        data: formData,
      );

      return EquipmentOperation.fromJson(response.data['operation']);
    } catch (e) {
      throw Exception('Failed to finish operation: $e');
    }
  }

  /// Get equipment list
  Future<List<Equipment>> getEquipment() async {
    try {
      final response = await _dio.get(ApiConstants.eqpEquipmentEndpoint);
      final data = response.data as List;
      return data.map((json) => Equipment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load equipment: $e');
    }
  }

  /// Get activities list
  Future<List<Activity>> getActivities() async {
    try {
      final response = await _dio.get(ApiConstants.eqpActivitiesEndpoint);
      final data = response.data as List;
      return data.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load activities: $e');
    }
  }

  /// Get locations list
  Future<List<Location>> getLocations() async {
    try {
      final response = await _dio.get(ApiConstants.eqpLocationsEndpoint);
      final data = response.data as List;
      return data.map((json) => Location.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load locations: $e');
    }
  }
}

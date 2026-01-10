import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/equipment_operation.dart';
import '../models/equipment.dart';
import '../models/activity.dart';
import '../models/location.dart';
import '../models/task.dart';
import '../models/equipment_operation_requests.dart';
import 'database_helper.dart';

class EquipmentOperationService {
  final Dio _dio;

  EquipmentOperationService() : _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Accept': 'application/json', // Force JSON response from Laravel
      },
      validateStatus: (status) {
        return status! < 500; // Allow 4xx errors to be handled by our code
      },
    ),
  ) {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        


        // Correctly retrieve token from 'userData' which stores it as a JSON string
        String? token;
        if (prefs.containsKey('userData')) {
          final userDataStr = prefs.getString('userData');

          if (userDataStr != null) {
            try {
              final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
              token = userData['token'];
            } catch (e) {
              // print('DEBUG: Error decoding userData: $e');
            }
          }
        } else {

        }

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token'; // Ensure Bearer prefix
        } else {
          print('DEBUG: WARNING - No token found!');
        }
        
        // print('DEBUG: Requesting: ${options.uri}');
        // print('DEBUG: Headers: ${options.headers}');
        // print('DEBUG: Token being used: $token');

        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle errors globally
        print('API Error: ${e.message}');
        print('DEBUG: Dio Error: ${e.message}');
        if (e.response != null) {
           print('DEBUG: Error Data: ${e.response?.data}');
        }
        return handler.next(e);
      },
    ));
  }

  /// Get paginated list of operations
  Future<PaginatedResponse<EquipmentOperation>> getOperations({
    required int page,
    int? equipmentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page};
      
      if (equipmentId != null) {
        queryParams['equipment_id'] = equipmentId;
      }
      
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _dio.get(
        ApiConstants.eqpOperationsEndpoint,
        queryParameters: queryParams,
      );

      var responseData = response.data;
      
      /*
      print('DEBUG: getOperations Response Type: ${responseData.runtimeType}');
      if (responseData is List) {
         print('DEBUG: Response is List. Length: ${responseData.length}');
      } else if (responseData is Map) {
         print('DEBUG: Response is Map. Keys: ${responseData.keys}');
         if (responseData.containsKey('error')) {
             print('DEBUG: API RETURNED ERROR: ${responseData['error']}');
             throw Exception(responseData['error']);
         }
         if (responseData['data'] != null) {
            print('DEBUG: Map["data"] type: ${responseData['data'].runtimeType}');
         }
      }
      */

      List<EquipmentOperation> operations = [];
      int currentPage = 1;
      int lastPage = 1;
      int perPage = 20;
      int total = 0;

      // Handle Direct List Response (Production?)
      if (responseData is List) {
        operations = responseData.map((json) => EquipmentOperation.fromJson(json)).toList();
        total = operations.length;
      } 
      // Handle Paginated Map Response (Test/Laravel Default)
      else if (responseData is Map) {
         if (responseData.containsKey('error')) {
             throw Exception(responseData['error']);
         }
         if (responseData['data'] is List) {
            final list = responseData['data'] as List;
            operations = list.map((json) => EquipmentOperation.fromJson(json)).toList();
            
            currentPage = int.tryParse(responseData['current_page']?.toString() ?? '1') ?? 1;
            lastPage = int.tryParse(responseData['last_page']?.toString() ?? '1') ?? 1;
            perPage = int.tryParse(responseData['per_page']?.toString() ?? '20') ?? 20;
            total = int.tryParse(responseData['total']?.toString() ?? '0') ?? 0;
         }
      }

      return PaginatedResponse(
        data: operations,
        currentPage: currentPage,
        lastPage: lastPage,
        perPage: perPage,
        total: total,
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

  /// Create a new operation
  Future<EquipmentOperation> createOperation(CreateOperationRequest request) async {
    try {
      final formData = await request.toFormData();
      
      print('DEBUG: Creating Operation...');
      final response = await _dio.post(
        ApiConstants.eqpOperationsEndpoint,
        data: formData,
      );

      print('DEBUG: Create Response Body: ${response.data}');
      
      var responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        return EquipmentOperation.fromJson(responseData['data']);
      } else if (responseData is Map<String, dynamic> && responseData.containsKey('operation')) {
         // Handle case where data is wrapped in 'operation' key
        return EquipmentOperation.fromJson(responseData['operation']);
      } else if (responseData is Map<String, dynamic>) {
        return EquipmentOperation.fromJson(responseData);
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print('DEBUG: Error creating operation: $e');
      throw Exception('Failed to create operation: $e');
    }
  }

  /// Add task to operation (with offline support)
  Future<Task?> addTask(String scrum, CreateTaskRequest request) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.eqpOperationsEndpoint}/$scrum/tasks',
        data: request.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      return Task.fromJson(response.data['task']);
    } on DioException catch (e) {
      // Check if it's a network error
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.error.toString().contains('SocketException')) {
        // Save to offline queue
        await DatabaseHelper.instance.addPendingTask(scrum, request.toJson());
        
        // Return null to indicate offline save
        return null;
      }
      throw Exception('Failed to add task: $e');
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  /// Create task from Map data (used by sync service)
  Future<Task> createTask(String scrum, Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.eqpOperationsEndpoint}/$scrum/tasks',
        data: taskData,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      return Task.fromJson(response.data['task']);
    } catch (e) {
      throw Exception('Failed to create task: $e');
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
      print('DEBUG: Fetching Equipment...'); 
      final response = await _dio.get(ApiConstants.eqpEquipmentEndpoint);
      print('DEBUG: Raw Response Type: ${response.data.runtimeType}');
      
      var responseData = response.data;

      // Handle String response (potentially manually encoded JSON or HTML error)
      if (responseData is String) {
        print('DEBUG: Response is STRING. First 200 chars: ${responseData.substring(0, responseData.length > 200 ? 200 : responseData.length)}');
        try {
          responseData = jsonDecode(responseData);
          print('DEBUG: Successfully manually decoded JSON String');
        } catch (e) {
          print('DEBUG: Failed to decode string as JSON: $e');
        }
      }

      var list = [];

      if (responseData is List) {
        print('DEBUG: Response is a DIRECT LIST');
        list = responseData;
      } else if (responseData is Map<String, dynamic>) {
        print('DEBUG: Response is a MAP. Keys: ${responseData.keys.toList()}');
        
        if (responseData['data'] is List) {
           print('DEBUG: Response is a MAP with DATA list');
           list = responseData['data'];
        } else {
           // Maybe the map ITSELF contains the list under a different key?
           // or maybe we need to values?
           print('DEBUG: Map does NOT contain "data" list.');
        }
      } else {
        print('DEBUG: UNEXPECTED RESPONSE FORMAT!');
      }

      print('DEBUG: List length: ${list.length}');
      
      return list.map((json) => Equipment.fromJson(json)).toList();
    } catch (e) {
      print('DEBUG: Error in getEquipment: $e');
      throw Exception('Failed to load equipment: $e');
    }
  }

  /// Get activities list
  Future<List<Activity>> getActivities() async {
    try {
      final response = await _dio.get(ApiConstants.eqpActivitiesEndpoint);
      var responseData = response.data;
      var list = [];

      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map<String, dynamic> && responseData['data'] is List) {
        list = responseData['data'];
      }

      return list.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load activities: $e');
    }
  }

  /// Get locations list
  Future<List<Location>> getLocations() async {
    try {
      final response = await _dio.get(ApiConstants.eqpLocationsEndpoint);
      var responseData = response.data;
      var list = [];

      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map<String, dynamic> && responseData['data'] is List) {
        list = responseData['data'];
      }

      return list.map((json) => Location.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load locations: $e');
    }
  }
}

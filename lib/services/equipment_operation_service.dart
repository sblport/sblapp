import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/equipment_operation.dart';
import '../models/equipment.dart';
import '../models/activity.dart';
import '../models/location.dart';
import '../models/organization.dart';
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


  /// Get all organizations
  Future<List<Organization>> getOrganizations() async {
    try {
      final response = await _dio.get(ApiConstants.eqpOrgsEndpoint);
      print('DEBUG: Orgs Response API: ${response.data}');
      
      dynamic responseData = response.data;
      List<dynamic> listData;
      
      if (responseData is List) {
        listData = responseData;
      } else if (responseData is Map && responseData.containsKey('data') && responseData['data'] is List) {
        listData = responseData['data'];
      } else {
        print('DEBUG: Unexpected format. Type: ${responseData.runtimeType}');
        return []; // Return empty list instead of throwing to prevent blocking ui?
      }

      return listData.map((json) => Organization.fromJson(json)).toList();
    } catch (e) {
      print('DEBUG: Error in getOrganizations: $e');
      throw Exception('Failed to load organizations: $e');
    }
  }

  /// Add task to operation (with offline support)
  Future<Task?> addTask(String scrum, CreateTaskRequest request) async {
    try {
      final jsonData = request.toJson();
      print('DEBUG: Creating task with data: $jsonData');
      
      final response = await _dio.post(
        '${ApiConstants.eqpOperationsEndpoint}/$scrum/tasks',
        data: jsonData,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      return Task.fromJson(response.data['task']);
    } on DioException catch (e) {
      print('DEBUG: DioException - Type: ${e.type}, Message: ${e.message}');
      print('DEBUG: Response data: ${e.response?.data}');
      print('DEBUG: Status code: ${e.response?.statusCode}');
      
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
      
      // Rethrow 400 errors so UI can handle (e.g. unfinished task)
      if (e.response?.statusCode == 400) {
        rethrow;
      }

      throw Exception('Failed to add task: $e');
    } catch (e) {
      print('DEBUG: General exception: $e');
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

  /// Delete task
  Future<void> deleteTask(String scrum, String taskId) async {
    try {
      await _dio.delete(
        '${ApiConstants.eqpOperationsEndpoint}/$scrum/tasks/$taskId',
      );
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Finish task
  Future<Task> finishTask(
    String scrum,
    int taskId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.eqpOperationsEndpoint}/$scrum/tasks/$taskId/finish',
        data: payload,
      );

      // Handle different response formats from backend
      if (response.data == null) {
        throw Exception('Backend returned null response');
      }
      
      // Check if data is wrapped in 'task' key or returned directly
      dynamic taskData;
      if (response.data is Map<String, dynamic>) {
        taskData = response.data['task'] ?? response.data;
      } else {
        taskData = response.data;
      }
        
      return Task.fromJson(taskData as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        rethrow;
      }
      throw Exception('Failed to finish task: $e');
    }
  }


  /// Approve operation
  Future<EquipmentOperation> approveOperation(String scrum) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.eqpOperationsEndpoint}/$scrum/approve',
      );
      
      final opData = response.data['operation'];
      if (opData == null) {
          // If the API returns success but no operation data, we might need to fetch it separately
          // Or it might be a weird backend behavior.
          // For now, let's try to fetch it again if data is missing, or throw more descriptive error
           return await getOperation(scrum);
      }
      
      return EquipmentOperation.fromJson(opData);
    } catch (e) {
      throw Exception('Failed to approve operation: $e');
    }
  }

  /// Finish operation
  /// Finish operation
  Future<EquipmentOperation> finishOperation(
    String scrum,
    FinishOperationRequest request, {
    void Function(int sent, int total)? onProgress,
  }) async {
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
        onSendProgress: onProgress,
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
  /// Get equipment last HM
  Future<double?> getLastHm(int equipmentId) async {
    try {
      final response = await _dio.get('${ApiConstants.eqpEquipmentEndpoint}/$equipmentId/last-hm');
      
      if (response.data is Map && response.data.containsKey('last_hm')) {
        final val = response.data['last_hm'];
        return val != null ? double.tryParse(val.toString()) : 0.0;
      }
      return 0.0;
    } catch (e) {
      print('DEBUG: Error fetching last HM: $e');
      return 0.0;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../constants/api_constants.dart';
import '../models/attendance_model.dart';
import 'package:flutter/foundation.dart';

class AttendanceService {
  Future<List<AttendanceLog>> getWorkHours({
    required String token,
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startStr = dateFormat.format(startDate);
    final endStr = dateFormat.format(endDate);

    // Construct URI with query parameters manually or using Uri.https/http if needed, 
    // but Uri.parse + replace(queryParameters) is standard.
    // Note: This will standard URL encode parameters.
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.workhourEndpoint}').replace(
      queryParameters: {
        'start_date': startStr,
        'end_date': endStr,
        'employee_id': employeeId,
      },
    );
    
    // Debug print
    if (kDebugMode) {
      print('Fetching URL: $uri');
    }

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (kDebugMode) {
          print('Attendance Response: $data');
        }
        
        List<dynamic> listCallback = [];
        if (data is List) {
          listCallback = data;
        } else if (data is Map && data['data'] is List) {
          listCallback = data['data'];
        }

        return listCallback.map((e) => AttendanceLog.fromJson(e)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to load attendance: ${response.body}');
        }
        throw Exception('Failed to load attendance: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching attendance: $e');
      }
      rethrow;
    }
  }
}

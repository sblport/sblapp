import 'dart:io';
import 'package:dio/dio.dart';

class CreateOperationRequest {
  final int equipmentId;
  final DateTime date;
  final String shift;
  final double opsHmStart;
  final File photo;

  CreateOperationRequest({
    required this.equipmentId,
    required this.date,
    required this.shift,
    required this.opsHmStart,
    required this.photo,
  });

  Map<String, dynamic> toMap() {
    return {
      'equipment_id': equipmentId.toString(),
      'date': date.toIso8601String().split('T')[0],
      'shift': shift,
      'ops_hm_start': opsHmStart.toString(),
    };
  }

  Future<FormData> toFormData() async {
    return FormData.fromMap({
      ...toMap(),
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split('/').last,
      ),
    });
  }
}

class CreateTaskRequest {
  final DateTime taskStart;
  final DateTime taskEnd;
  final double? hmStart;
  final double? hmEnd;
  final int activityId;
  final int locationId;
  final String? code;
  final String? result;
  final String? remarks;
  final int? orderBy;

  CreateTaskRequest({
    required this.taskStart,
    required this.taskEnd,
    this.hmStart,
    this.hmEnd,
    required this.activityId,
    required this.locationId,
    this.code,
    this.result,
    this.remarks,
    this.orderBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'task_start': taskStart.toIso8601String(),
      'task_end': taskEnd.toIso8601String(),
      'hm_start': hmStart,
      'hm_end': hmEnd,
      'activity_id': activityId,
      'location_id': locationId,
      'code': code,
      'result': result,
      'remarks': remarks,
      'order_by': orderBy,
    };
  }
}

class FinishOperationRequest {
  final double opsHmEnd;
  final File photo2;

  FinishOperationRequest({
    required this.opsHmEnd,
    required this.photo2,
  });

  Map<String, dynamic> toMap() {
    return {
      'ops_hm_end': opsHmEnd.toString(),
    };
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMorePages => currentPage < lastPage;
}

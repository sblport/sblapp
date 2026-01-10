import 'activity.dart';
import 'location.dart';

class Task {
  final int id;
  final DateTime taskStart;
  final DateTime taskEnd;
  final double? hmStart;
  final double? hmEnd;
  final Activity? activity;
  final Location? location;
  final String? code;
  final String? result;
  final String? remarks;

  Task({
    required this.id,
    required this.taskStart,
    required this.taskEnd,
    this.hmStart,
    this.hmEnd,
    this.activity,
    this.location,
    this.code,
    this.result,
    this.remarks,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: int.tryParse(json['id'].toString()) ?? 0,
      taskStart: DateTime.parse(json['task_start'] as String),
      taskEnd: DateTime.parse(json['task_end'] as String),
      hmStart: json['hm_start'] != null 
          ? double.tryParse(json['hm_start'].toString()) 
          : null,
      hmEnd: json['hm_end'] != null 
          ? double.tryParse(json['hm_end'].toString()) 
          : null,
      activity: json['activities'] != null 
          ? Activity.fromJson(json['activities'] as Map<String, dynamic>) 
          : null,
      location: json['locations'] != null 
          ? Location.fromJson(json['locations'] as Map<String, dynamic>) 
          : null,
      code: json['code'] as String?,
      result: json['result'] as String?,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_start': taskStart.toIso8601String(),
      'task_end': taskEnd.toIso8601String(),
      'hm_start': hmStart,
      'hm_end': hmEnd,
      'activity_id': activity?.id,
      'location_id': location?.id,
      'code': code,
      'result': result,
      'remarks': remarks,
    };
  }

  Duration get duration => taskEnd.difference(taskStart);

  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

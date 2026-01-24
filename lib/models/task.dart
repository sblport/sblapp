import 'activity.dart';
import 'location.dart';

class Task {
  final int id;
  final DateTime taskStart;
  final DateTime? taskEnd;
  final double? hmStart;
  final double? hmEnd;
  final Activity? activity;
  final Location? location;
  final String? code;
  final String? result;
  final String? remarks;
  final int? orderBy;

  Task({
    required this.id,
    required this.taskStart,
    this.taskEnd,
    this.hmStart,
    this.hmEnd,
    this.activity,
    this.location,
    this.code,
    this.result,
    this.remarks,
    this.orderBy,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: int.tryParse(json['id'].toString()) ?? 0,
      // Backend sends GMT+7 times like "2026-01-22 10:18:00" without timezone
      // Parse and treat as local (not UTC) to avoid conversion
      taskStart: _parseAsLocal(json['task_start'] as String),
      taskEnd: json['task_end'] != null 
          ? _parseAsLocal(json['task_end'] as String)
          : null,
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
      orderBy: json['order_by'] != null 
          ? int.tryParse(json['order_by'].toString()) 
          : null,
    );
  }

  // Helper to parse datetime as local without UTC conversion
  static DateTime _parseAsLocal(String dateTimeString) {
    // Parse the datetime string
    final parsed = DateTime.parse(dateTimeString);
    
    // If it's already local (has no Z), just return it
    if (!dateTimeString.endsWith('Z') && !dateTimeString.contains('+')) {
      // Treat as local time in current timezone
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
      );
    }
    
    return parsed.toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_start': taskStart.toIso8601String(),
      'task_end': taskEnd?.toIso8601String(),
      'hm_start': hmStart,
      'hm_end': hmEnd,
      'activity_id': activity?.id,
      'location_id': location?.id,
      'code': code,
      'result': result,
      'remarks': remarks,
      'order_by': orderBy,
    };
  }

  bool get isOngoing => taskEnd == null;
  bool get isCompleted => taskEnd != null;

  Duration? get duration => taskEnd != null 
      ? taskEnd!.difference(taskStart) 
      : null;

  String get durationText {
    if (duration == null) return 'Ongoing';
    
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

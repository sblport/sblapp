import 'equipment.dart';
import 'task.dart';
import 'user_model.dart';

class EquipmentOperation {
  final int id;
  final String scrum;
  final int equipmentId;
  final DateTime date;
  final String shift;
  final int userId;
  final double opsHmStart;
  final double? opsHmEnd;
  final int? photoId;
  final int? photo2Id;
  final String? photoUrl;
  final String? photo2Url;
  final Equipment? equipment;
  final User? user;
  final List<Task>? tasks;
  final DateTime createdAt;

  EquipmentOperation({
    required this.id,
    required this.scrum,
    required this.equipmentId,
    required this.date,
    required this.shift,
    required this.userId,
    required this.opsHmStart,
    this.opsHmEnd,
    this.photoId,
    this.photo2Id,
    this.photoUrl,
    this.photo2Url,
    this.equipment,
    this.user,
    this.tasks,
    required this.createdAt,
  });

  factory EquipmentOperation.fromJson(Map<String, dynamic> json) {
    return EquipmentOperation(
      id: int.tryParse(json['id'].toString()) ?? 0,
      scrum: json['scrum']?.toString() ?? '',
      equipmentId: int.tryParse(json['equipment_id'].toString()) ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      shift: json['shift']?.toString() ?? 'Day',
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      opsHmStart: double.tryParse(json['ops_hm_start'].toString()) ?? 0.0,
      opsHmEnd: json['ops_hm_end'] != null 
          ? double.tryParse(json['ops_hm_end'].toString()) 
          : null,
      photoId: json['photo_id'] != null ? int.tryParse(json['photo_id'].toString()) : null,
      photo2Id: json['photo2_id'] != null ? int.tryParse(json['photo2_id'].toString()) : null,
      photoUrl: json['photo_url']?.toString(),
      photo2Url: json['photo2_url']?.toString(),
      equipment: json['equipment'] != null 
          ? Equipment.fromJson(json['equipment'] as Map<String, dynamic>) 
          : null,
      user: json['user'] != null 
          ? User.fromJson(json['user'] as Map<String, dynamic>) 
          : null,
      tasks: json['tasks'] != null 
          ? (json['tasks'] as List).map((task) => Task.fromJson(task as Map<String, dynamic>)).toList() 
          : null,
      createdAt: json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scrum': scrum,
      'equipment_id': equipmentId,
      'date': date.toIso8601String().split('T')[0],
      'shift': shift,
      'user_id': userId,
      'ops_hm_start': opsHmStart,
      'ops_hm_end': opsHmEnd,
      'photo_id': photoId,
      'photo2_id': photo2Id,
      'photo_url': photoUrl,
      'photo2_url': photo2Url,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isFinished => opsHmEnd != null;

  String get statusText => isFinished ? 'Finished' : 'In Progress';

  double? get totalHours {
    if (opsHmEnd != null) {
      return opsHmEnd! - opsHmStart;
    }
    return null;
  }

  String get displayDate {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year}';
  }
}

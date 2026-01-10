class AttendanceLog {
  final String date;
  final String checkIn;
  final String checkOut;
  final bool isLate;
  final String lateMinutes;
  final String workhourReal;
  final String workhourCalculated;
  final String workhourFinal;

  AttendanceLog({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.isLate,
    required this.lateMinutes,
    required this.workhourReal,
    required this.workhourCalculated,
    required this.workhourFinal,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      date: json['date'] ?? '',
      checkIn: json['check_in'] ?? '--:--',
      checkOut: json['check_out'] ?? '--:--',
      isLate: json['is_late'] == true || json['is_late'] == 1 || json['is_late'] == '1',
      lateMinutes: json['late_minutes']?.toString() ?? '0',
      workhourReal: json['workhour_real'] ?? '-',
      workhourCalculated: json['workhour_calculated'] ?? '-',
      workhourFinal: json['workhour_final'] ?? '-',
    );
  }
}

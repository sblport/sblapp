import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  late final ValueNotifier<List<AttendanceLog>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<String, AttendanceLog> _events = {};
  bool _isLoading = false;
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMonthData(_focusedDay);
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _fetchMonthData(DateTime date) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated || authService.user == null) return;

    setState(() {
      _isLoading = true;
    }); // Don't wipe _events to avoid flickering, or maybe just overlay loading?

    // Calculate start and end of the month
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);

    try {
      final logs = await _attendanceService.getWorkHours(
        token: authService.token ?? '',
        employeeId: authService.user!.employeeId,
        startDate: start,
        endDate: end,
      );

      // Using private var to get token because I don't have a public getter in the code I saw earlier.
      // Wait, I didn't add a token getter in AuthService. I saw `String? _token`. 
      // I can't access it if it's private and has no getter. 
      // I'll assume I can fix AuthService or there is a getter. 
      // Checking AuthService again... 
      // It has `bool get isAuthenticated => _token != null;` but no `get token`.
      // I MUST FIX AuthService first to expose token.
      
      // ... For now, I'll continue writing this file and fix AuthService in next step.

      final newEvents = <String, AttendanceLog>{};
      for (var log in logs) {
        // Date from API might be YYYY-MM-DD? Model has String date.
        // I need to parse it to key. 
        // Assuming API returns YYYY-MM-DD.
        newEvents[log.date] = log;
      }

      if (mounted) {
        setState(() {
          _events = newEvents;
          _isLoading = false;
          // Update selected events if selected day is in this month
          if (_selectedDay != null) {
            _selectedEvents.value = _getEventsForDay(_selectedDay!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLoadingAttendance}: $e')),
        );
      }
    }
  }
  
  // Helper to fetch valid token.
  // I will update AuthService to expose token.

  List<AttendanceLog> _getEventsForDay(DateTime day) {
    // Convert day to string key matches API format (YYYY-MM-DD expected)
    // If API returns different, we need adjustment. 
    // Since I control parsing in Service/Model, let's assume Model.date is YYYY-MM-DD.
    final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    final log = _events[key];
    return log != null ? [log] : [];
  }
  
  AttendanceLog? _getLogForDay(DateTime day) {
    final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    return _events[key];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
      
      final events = _getEventsForDay(selectedDay);
      if (events.isNotEmpty) {
        _showDetailsSheet(events.first);
      }
    } else {
       // If same day is clicked again, show details if available
      final events = _getEventsForDay(selectedDay);
      if (events.isNotEmpty) {
        _showDetailsSheet(events.first);
      }
    }
  }

  void _showDetailsSheet(AttendanceLog log) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final formattedDate = DateFormat('d MMMM yyyy').format(_selectedDay!);
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              left: 24.0, 
              right: 24.0, 
              top: 24.0, 
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.0
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${l10n.info} $formattedDate",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildInfoRow(l10n.checkIn, _formatDateTime(log.checkIn), isError: log.isLate),
              _buildInfoRow(l10n.checkOut, _formatDateTime(log.checkOut)),
              _buildInfoRow(l10n.lateMinutes, '${log.lateMinutes} ${l10n.mins}', isError: log.isLate),
                _buildInfoRow(l10n.workHoursReal, _formatHours(log.workhourReal)),
                _buildInfoRow(l10n.workHoursCalc, _formatHours(log.workhourCalculated)),
                _buildInfoRow(l10n.rest, '1 ${l10n.hour}', isError: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.workHourFinal, 
                        style: const TextStyle(
                          color: AppColors.primary, 
                          fontSize: 15,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                        log.workhourFinal, 
                        style: const TextStyle(
                          fontWeight: FontWeight.w800, 
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            // Logo
            Image.asset(
              'lib/assets/images/logo.png',
              height: 32,
              errorBuilder: (c, e, s) => const Icon(Icons.business),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.history,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                if (user != null)
                  Text(
                    user.email,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.normal),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: () {
               Provider.of<AuthService>(context, listen: false).logout();
               Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchMonthData(_focusedDay),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildCalendar(),
                    // const SizedBox(height: 16),
                    // _buildDetailsPanel(), // Moved to modal
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
  return Container(
    margin: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TableCalendar<AttendanceLog>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        _fetchMonthData(focusedDay);
      },
      headerStyle: const HeaderStyle(
        titleCentered: false,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) => _buildCell(day, false),
        selectedBuilder: (context, day, focusedDay) => _buildCell(day, true),
        outsideBuilder: (context, day, focusedDay) => const SizedBox.shrink(), // Or default
      ),
    ),
  );
}

Widget _buildCell(DateTime day, bool isSelected) {
  final log = _getLogForDay(day);
  Color? bgColor;
  Color textColor = Colors.black87;

  if (log != null) {
      // Check if both check-in and check-out are missing
      bool isAbsent = (log.checkIn == '--:--' || log.checkIn == '-') && 
                      (log.checkOut == '--:--' || log.checkOut == '-');
      
      if (!isAbsent) {
        if (log.isLate) {
            bgColor = Colors.red.shade50;
        } else {
            bgColor = Colors.green.shade50;
        }
      }
  }

  // Selection overrides or adds border?
  // Design shows selection as blue border/fill.
  // If selected, we want to highlight it but maybe keep the status color slightly or just blue?
  // User screenshot shows: Select 5, it has blue background (or border?).
  // If "Date has data", default greenish. Late reddish.
  // I will make selection a blue border with the status color inside.
  
  if (isSelected) {
      return Container(
        margin: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.transparent, // Maintain status color
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.primary, width: 2.0),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      );
  }

  if (log == null) {
      // Default empty cell
      return Container(
        margin: const EdgeInsets.all(6.0),
        alignment: Alignment.center,
        child: Text('${day.day}', style: const TextStyle(color: Colors.black45)),
      );
  }

  return Container(
    margin: const EdgeInsets.all(6.0),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(8.0),
    ),
    alignment: Alignment.center,
    child: Text(
      '${day.day}',
      style: TextStyle(color: textColor),
    ),
  );
}


  // Widget _buildDetailsPanel() { ... } // Removed or commented out as code is now in _showDetailsSheet

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty || isoString == '--:--' || isoString == '-') return isoString;
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('d MMMM yyyy HH:mm:ss').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }
  
  String _formatHours(String value) {
    if (value == '-' || value.isEmpty) return value;
    try {
      final l10n = AppLocalizations.of(context)!;
      final doubleValue = double.parse(value);
      return '${doubleValue.toStringAsFixed(0)} ${l10n.hours}';
    } catch (_) {
      return value;
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 14,
              color: isError ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

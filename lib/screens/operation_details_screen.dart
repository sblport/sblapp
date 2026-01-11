import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../constants/app_colors.dart';
import '../providers/equipment_operation_provider.dart';
import '../services/auth_service.dart';
import '../models/equipment_operation.dart';
import '../models/task.dart';
import '../models/equipment_operation_requests.dart';
import '../models/activity.dart';
import '../models/location.dart';
import '../models/organization.dart';

class OperationDetailsScreen extends StatefulWidget {
  final String scrum;

  const OperationDetailsScreen({super.key, required this.scrum});

  @override
  State<OperationDetailsScreen> createState() => _OperationDetailsScreenState();
}

class _OperationDetailsScreenState extends State<OperationDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _loadOperation();
  }

  void _loadOperation() {
    final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
    provider.loadOperation(widget.scrum);
  }

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskSheet(scrum: widget.scrum),
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) => _FinishOperationDialog(scrum: widget.scrum),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
      final success = await provider.deleteTask(widget.scrum, taskId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.operationError ?? 'Failed to delete task')),
          );
        }
      }
    }
  }

  Future<void> _approveOperation() async {
    final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
    final success = await provider.approveOperation(widget.scrum);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation Approved!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.operationError ?? 'Failed to approve operation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewFullImage(String? url) {
    if (url == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final isSupervisor = user?.hakakses.any((h) => h.deptId == 9 && h.level >= 2) ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Operation Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<EquipmentOperationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingOperation) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.operationError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load operation'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOperation,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final operation = provider.currentOperation;
          if (operation == null) {
            return const Center(child: Text('Operation not found'));
          }

          // Approve Button Logic
          // Show if Finished + Not Approved
          // Optional: Check permission (isSupervisor)
          final canApprove = operation.isFinished && !operation.isApproved && isSupervisor;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Operation Info Card
                    _OperationInfoCard(
                      operation: operation,
                      onPhotoTap: _viewFullImage,
                    ),
                    const SizedBox(height: 16),

                    // Tasks Section
                    _TasksSection(
                      operation: operation,
                      onAddTask: !operation.isFinished ? _showAddTaskDialog : null,
                      onDeleteTask: !operation.isFinished ? _deleteTask : null,
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              if (!operation.isFinished)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: _showFinishDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Finish Operation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

              if (canApprove)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: _approveOperation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Approve Operation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OperationInfoCard extends StatelessWidget {
  final EquipmentOperation operation;
  final Function(String?) onPhotoTap;

  const _OperationInfoCard({
    required this.operation,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    if (operation.isApproved) {
      statusColor = Colors.green;
      statusText = 'Approved';
    } else if (operation.isFinished) {
      statusColor = Colors.amber[700]!;
      statusText = 'Finished (Pending)';
    } else {
      statusColor = Colors.blue;
      statusText = 'Ongoing';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: operation.shift == 'Day' ? Colors.amber[600] : Colors.indigo[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      operation.shift,
                      style: TextStyle(
                        color: operation.shift == 'Day' ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Equipment Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        operation.equipment?.code ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (operation.equipment?.category != null)
                        Text(
                          '${operation.equipment!.category} ${operation.equipment!.brand != null ? '(${operation.equipment!.brand})' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Details
            _InfoRow(icon: Icons.calendar_today, label: 'Date', value: operation.displayDate),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.person, label: 'Operator', value: operation.user?.name ?? 'Unknown'),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.speed,
              label: 'HM Start',
              value: operation.opsHmStart.toStringAsFixed(1),
            ),
            if (operation.opsHmEnd != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.speed,
                label: 'HM End',
                value: operation.opsHmEnd!.toStringAsFixed(1),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Total Hours',
                value: '${operation.totalHours!.toStringAsFixed(1)} hours',
              ),
            ],

            // Photos
            if (operation.photoUrl != null || operation.photo2Url != null) ...[
              const Divider(height: 24),
              const Text(
                'Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (operation.photoUrl != null)
                    Expanded(
                      child: _PhotoThumbnail(
                        url: operation.photoUrl!,
                        label: 'Start Photo',
                        onTap: () => onPhotoTap(operation.photoUrl),
                      ),
                    ),
                  if (operation.photoUrl != null && operation.photo2Url != null)
                    const SizedBox(width: 12),
                  if (operation.photo2Url != null)
                    Expanded(
                      child: _PhotoThumbnail(
                        url: operation.photo2Url!,
                        label: 'End Photo',
                        onTap: () => onPhotoTap(operation.photo2Url),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String url;
  final String label;
  final VoidCallback onTap;

  const _PhotoThumbnail({
    required this.url,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 100,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 100,
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TasksSection extends StatelessWidget {
  final EquipmentOperation operation;
  final VoidCallback? onAddTask;
  final Function(String taskId)? onDeleteTask;

  const _TasksSection({
    required this.operation,
    this.onAddTask,
    this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = operation.tasks ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Tasks Timeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (onAddTask != null)
                  TextButton.icon(
                    onPressed: onAddTask,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Task'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (tasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.task_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No tasks yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...tasks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                return _TaskTimelineItem(
                  task: task,
                  isFirst: index == 0,
                  isLast: index == tasks.length - 1,
                  onDelete: onDeleteTask != null ? () => onDeleteTask!(task.id.toString()) : null,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _TaskTimelineItem extends StatelessWidget {
  final Task task;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onDelete;

  const _TaskTimelineItem({
    required this.task,
    required this.isFirst,
    required this.isLast,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 24,
        color: AppColors.primary,
        iconStyle: IconStyle(
          iconData: Icons.check_circle,
          color: Colors.white,
        ),
      ),
      beforeLineStyle: LineStyle(
        color: Colors.grey[300]!,
        thickness: 2,
      ),
      endChild: Container(
        margin: const EdgeInsets.only(left: 12, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.activity?.name ?? 'Unknown Activity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDelete != null)
                  InkWell(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  task.location?.name ?? 'Unknown',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(task.taskStart)} - ${_formatTime(task.taskEnd)} (${task.durationText})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            if (task.hmStart != null && task.hmEnd != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.speed, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'HM: ${task.hmStart!.toStringAsFixed(1)} → ${task.hmEnd!.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (task.code != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.qr_code, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    task.code!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (task.result != null || task.remarks != null) ...[
              const SizedBox(height: 8),
              if (task.result != null)
                Text(
                  'Result: ${task.result}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              if (task.remarks != null)
                Text(
                  'Remarks: ${task.remarks}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    // Ensure we display local time for user
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _AddTaskSheet extends StatefulWidget {
  final String scrum;

  const _AddTaskSheet({required this.scrum});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _resultController = TextEditingController();
  final _remarksController = TextEditingController();
  final _hmStartController = TextEditingController();
  final _hmEndController = TextEditingController();

  DateTime _taskStart = DateTime.now();
  DateTime _taskEnd = DateTime.now().add(const Duration(hours: 2));
  Activity? _selectedActivity;
  Location? _selectedLocation;
  Organization? _selectedOrganization;
  bool _isSubmitting = false;
  String? _timeValidationError; // Track time validation error
  bool _isFirstTask = false;


  @override
  void initState(){
    super.initState();
    _loadDefaultValues();
    _checkReferenceData();
  }

  void _checkReferenceData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
      if (provider.activities.isEmpty || provider.locations.isEmpty || provider.organizations.isEmpty) {
        provider.loadReferenceData();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resultController.dispose();
    _remarksController.dispose();
    _hmStartController.dispose();
    _hmEndController.dispose();
    super.dispose();
  }

  void _loadDefaultValues() {
    final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
    final operation = provider.currentOperation;
    
    if (operation != null) {
      final tasks = operation.tasks ?? [];
      final operationDate = operation.date; // Get operation date
      
      // Set task start time
      if (tasks.isNotEmpty) {
        _isFirstTask = false;
        // Use previous task's end time
        final lastTask = tasks.last;
        _taskStart = DateTime(
          operationDate.year,
          operationDate.month,
          operationDate.day,
          lastTask.taskEnd.hour,
          lastTask.taskEnd.minute,
        );
        
        // HM Start from previous task's HM End
        if (lastTask.hmEnd != null) {
          _hmStartController.text = lastTask.hmEnd!.toStringAsFixed(1);
        }
      } else {
        _isFirstTask = true;
        // First task: use current time
        final now = DateTime.now();
        _taskStart = DateTime(
          operationDate.year,
          operationDate.month,
          operationDate.day,
          now.hour,
          now.minute,
        );
        
        // HM Start from operation
        _hmStartController.text = operation.opsHmStart.toStringAsFixed(1);
      }
      
      // Task end = task start + 30 minutes
      _taskEnd = _taskStart.add(const Duration(minutes: 30));
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
    final operation = provider.currentOperation;
    
    if (operation == null) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _taskStart : _taskEnd),
    );

    if (time != null && mounted) {
      setState(() {
        final operationDate = operation.date;
        final newDateTime = DateTime(
          operationDate.year,
          operationDate.month,
          operationDate.day,
          time.hour,
          time.minute,
        );
        
        if (isStart) {
          _taskStart = newDateTime;
          // Auto-update task end to be 30 minutes after start (default behavior)
          _taskEnd = _taskStart.add(const Duration(minutes: 30));
        } else {
          _taskEnd = newDateTime;
        }

        // Calculate HM End based on Duration
        if (_taskEnd.isAfter(_taskStart) && _hmStartController.text.isNotEmpty) {
           final hmStart = double.tryParse(_hmStartController.text);
           if (hmStart != null) {
              final duration = _taskEnd.difference(_taskStart);
              // Convert duration to hours (decimal)
              final hours = duration.inMinutes / 60.0;
              final hmEnd = hmStart + hours;
              // Round to 1 decimal place
              _hmEndController.text = hmEnd.toStringAsFixed(1);
           }
        }
        
        // Clear validation error when time changes
        _timeValidationError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedActivity == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select activity and location')),
      );
      return;
    }
    
    // Validate task end is after task start
    if (_taskEnd.isBefore(_taskStart) || _taskEnd.isAtSameMomentAs(_taskStart)) {
      setState(() {
        _timeValidationError = 'Task End must be after Task Start';
      });
      return;
    }
    
    // Clear any previous time validation error
    setState(() {
      _timeValidationError = null;
    });

    setState(() => _isSubmitting = true);

    try {
      final request = CreateTaskRequest(
        taskStart: _taskStart,
        taskEnd: _taskEnd,
        hmStart: _hmStartController.text.isNotEmpty 
            ? double.tryParse(_hmStartController.text) 
            : null,
        hmEnd: _hmEndController.text.isNotEmpty 
            ? double.tryParse(_hmEndController.text) 
            : null,
        activityId: _selectedActivity!.id,
        locationId: _selectedLocation!.id,
        code: _codeController.text.isNotEmpty ? _codeController.text : null,
        result: _resultController.text.isNotEmpty ? _resultController.text : null,
        remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
        orderBy: _selectedOrganization?.id,
      );

      final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
      final success = await provider.addTask(widget.scrum, request);

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Saved offline
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📴 Task saved offline. Will sync when online.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Add Task',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: Consumer<EquipmentOperationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingReferenceData) { // Assume getter exists
                       return const Center(child: CircularProgressIndicator());
                    }
                    return Form(
                      key: _formKey,
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Task Start Time (Time only)
                          InkWell(
                            onTap: _isFirstTask ? () => _selectTime(true) : null,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: _isFirstTask ? 'Task Start *' : 'Task Start (Auto-filled)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.schedule),
                                filled: !_isFirstTask,
                                fillColor: !_isFirstTask ? Colors.grey[100] : null,
                              ),
                              child: Text(
                                _formatTime(_taskStart),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: !_isFirstTask ? Colors.grey[700] : null,
                                ),
                              ),
                            ),
                          ),
                          
                          // Show validation error if exists
                          if (_timeValidationError != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                _timeValidationError!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Task End Time (Time only)
                          InkWell(
                            onTap: () => _selectTime(false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Task End *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.schedule),
                              ),
                              child: Text(
                                _formatTime(_taskEnd),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Activity Dropdown
                          DropdownButtonFormField<Activity>(
                            value: _selectedActivity,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Activity *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.work),
                            ),
                            items: provider.activities.map((activity) {
                              return DropdownMenuItem(
                                value: activity,
                                child: Text(
                                  activity.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedActivity = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Location Dropdown
                          DropdownButtonFormField<Location>(
                            value: _selectedLocation,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Location *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.location_on),
                            ),
                            items: provider.locations.map((location) {
                              return DropdownMenuItem(
                                value: location,
                                child: Text(
                                  location.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Instructed By Dropdown
                          DropdownButtonFormField<Organization>(
                            value: _selectedOrganization,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Instructed By',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            items: provider.organizations.map((org) {
                              return DropdownMenuItem(
                                value: org,
                                child: Text(
                                  org.chartname,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedOrganization = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // HM Start (Read-only for subsequent tasks, Editable for first)
                          TextFormField(
                            controller: _hmStartController,
                            decoration: InputDecoration(
                              labelText: _isFirstTask ? 'HM Start' : 'HM Start (Auto-filled)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.speed),
                              filled: !_isFirstTask,
                              fillColor: !_isFirstTask ? Colors.grey[100] : null,
                            ),
                            readOnly: !_isFirstTask,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 16),

                          // HM End (Mandatory)
                          TextFormField(
                            controller: _hmEndController,
                            decoration: InputDecoration(
                              labelText: 'HM End *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.speed),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'HM End is required';
                              }
                              final hmEnd = double.tryParse(value);
                              if (hmEnd == null) {
                                return 'Please enter a valid number';
                              }
                              final hmStart = double.tryParse(_hmStartController.text);
                              if (hmStart != null && hmEnd < hmStart) {
                                return 'HM End must be greater than or equal to HM Start';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Code
                          TextFormField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText: 'Code (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.qr_code),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Result
                          TextFormField(
                            controller: _resultController,
                            decoration: InputDecoration(
                              labelText: 'Result (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.check_circle_outline),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // Remarks
                          TextFormField(
                            controller: _remarksController,
                            decoration: InputDecoration(
                              labelText: 'Remarks (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.note),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Add Task',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    // Ensure we display local time
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _FinishOperationDialog extends StatefulWidget {
  final String scrum;

  const _FinishOperationDialog({required this.scrum});

  @override
  State<_FinishOperationDialog> createState() => _FinishOperationDialogState();
}

class _FinishOperationDialogState extends State<_FinishOperationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hmEndController = TextEditingController();
  File? _photo2File;
  bool _isSubmitting = false;
  bool _isReadonly = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultValues();
  }

  @override
  void dispose() {
    _hmEndController.dispose();
    super.dispose();
  }

  void _loadDefaultValues() {
    final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
    final operation = provider.currentOperation;
    
    if (operation != null) {
      final tasks = operation.tasks ?? [];
      if (tasks.isNotEmpty) {
        final lastTask = tasks.last;
        if (lastTask.hmEnd != null) {
          _hmEndController.text = lastTask.hmEnd!.toStringAsFixed(1);
          _isReadonly = true;
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        
        // Check file size
        final fileSize = await imageFile.length();
        if (fileSize > 512 * 1024) { // > 512KB
          // Compress
          final compressedFile = await _compressImage(imageFile);
          if (compressedFile != null) {
            imageFile = compressedFile;
          }
        }
        
        setState(() {
          _photo2File = imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.parent.path}/compressed_${file.path.split('/').last}',
        quality: 70,
      );
      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Compression error: $e');
      return null;
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_photo2File == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take an end photo')),
      );
      return;
    }

    // Show Loading Dialog with progress
    final uploadProgress = ValueNotifier<double?>(null); // Start with null (indeterminate)
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ValueListenableBuilder<double?>(
          valueListenable: uploadProgress,
          builder: (context, progress, child) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: progress, // null = indeterminate, 0.0-1.0 = determinate
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    progress == null
                      ? 'Preparing upload...'
                      : 'Uploading: ${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (progress != null)
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.primary,
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      final request = FinishOperationRequest(
        opsHmEnd: double.parse(_hmEndController.text),
        photo2: _photo2File!,
      );

      final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
      final success = await provider.finishOperation(
        widget.scrum,
        request,
        onProgress: (sent, total) {
          if (total > 0 && sent >= 0) {
            final newProgress = sent / total;
            // Ensure value is finite (not NaN or Infinity)
            if (newProgress.isFinite && newProgress >= 0 && newProgress <= 1) {
              uploadProgress.value = newProgress;
            }
          }
        },
      );

      if (mounted) {
        Navigator.pop(context); // Close Loading Dialog first
        
        // Small delay before dispose to ensure dialog is fully closed
        await Future.delayed(const Duration(milliseconds: 100));
        uploadProgress.dispose();
        
        if (success) {
          Navigator.pop(context); // Close Finish Dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operation finished successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to finish operation')),
          );
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        Navigator.pop(context); // Close Loading Dialog
        await Future.delayed(const Duration(milliseconds: 100));
        uploadProgress.dispose();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Finish Operation'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7, // Max 70% of screen height
          maxWidth: 400,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              if (_isReadonly)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'HM End is set from last task',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // HM End
              TextFormField(
                controller: _hmEndController,
                readOnly: _isReadonly,
                decoration: InputDecoration(
                  labelText: 'Hour Meter End *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.speed),
                  suffixText: 'hours',
                  filled: _isReadonly,
                  fillColor: _isReadonly ? Colors.grey[100] : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter HM end';
                  }
                  final num? hmValue = double.tryParse(value);
                  if (hmValue == null || hmValue < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Photo Picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'End Photo *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (_photo2File != null)
                    SizedBox(
                      width: 300, // Fixed width instead of double.infinity
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _photo2File!,
                              height: 150,
                              width: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _photo2File = null;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32, color: Colors.grey[400]),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to add photo',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Finish'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/equipment_operation_provider.dart';

class FinishTaskScreen extends StatefulWidget {
  final String operationScrum;
  final Task task;

  const FinishTaskScreen({
    Key? key,
    required this.operationScrum,
    required this.task,
  }) : super(key: key);

  @override
  State<FinishTaskScreen> createState() => _FinishTaskScreenState();
}

class _FinishTaskScreenState extends State<FinishTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hmEndController = TextEditingController();
  final _resultController = TextEditingController();
  final _remarksController = TextEditingController();
  
  late DateTime _taskEnd;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _taskEnd = DateTime.now();
    _resultController.text = widget.task.result ?? '';
    _remarksController.text = widget.task.remarks ?? '';
    if (widget.task.hmEnd != null) {
      _hmEndController.text = widget.task.hmEnd!.toStringAsFixed(2);
    } else if (widget.task.hmStart != null) {
      _hmEndController.text = widget.task.hmStart!.toStringAsFixed(2);
    }
  }
  
  @override
  void dispose() {
    _hmEndController.dispose();
    _resultController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_taskEnd),
    );

    if (time != null && mounted) {
      setState(() {
         // Use the task start date, but with the selected time
         _taskEnd = DateTime(
            widget.task.taskStart.year,
            widget.task.taskStart.month,
            widget.task.taskStart.day,
            time.hour,
            time.minute,
         );
      });
    }
  }

  Future<void> _finishTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Simple validation: end time must be after start time (compare hours and minutes only)
    final startTime = widget.task.taskStart.hour * 60 + widget.task.taskStart.minute;
    final endTime = _taskEnd.hour * 60 + _taskEnd.minute;
    
    if (endTime <= startTime) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'task_end': _taskEnd.toIso8601String(),
        'hm_end': _hmEndController.text.isNotEmpty ? double.tryParse(_hmEndController.text) : null,
        'result': _resultController.text.isNotEmpty ? _resultController.text : null,
        'remarks': _remarksController.text.isNotEmpty ? _remarksController.text : null,
      };

      final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
      final success = await provider.finishTask(widget.operationScrum, widget.task.id, payload);

      if (mounted) {
        if (success) {
          Navigator.pop(context, true); // Return success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task finished successfully'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to finish task: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Finish Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
             Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity: ${widget.task.activity?.name ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Location: ${widget.task.location?.name ?? "-"}'),
                    const SizedBox(height: 8),
                    Text('Started: ${DateFormat.Hm().format(widget.task.taskStart)}'),
                    if (widget.task.hmStart != null) ...[
                      const SizedBox(height: 8),
                      Text('HM Start: ${widget.task.hmStart!.toStringAsFixed(2)}'),
                    ]
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // End Time
             InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Time',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.schedule),
                  ),
                  child: Text(
                    DateFormat.Hm().format(_taskEnd),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),

            // End HM
            TextFormField(
              controller: _hmEndController,
              decoration: InputDecoration(
                labelText: 'HM End',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.speed),
                hintText: widget.task.hmStart != null 
                    ? '>= ${widget.task.hmStart!.toStringAsFixed(2)}' 
                    : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.isEmpty) return null;
                final hmEnd = double.tryParse(val);
                if (hmEnd == null) return 'Invalid number';
                if (widget.task.hmStart != null && hmEnd < widget.task.hmStart!) {
                  return 'Must be >= ${widget.task.hmStart!.toStringAsFixed(2)}';
                }
                return null;
              },
            ),
            
             const SizedBox(height: 16),
            
            // Result
            TextFormField(
              controller: _resultController,
              decoration: InputDecoration(
                labelText: 'Result',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            
             const SizedBox(height: 16),

            // Remarks
            TextFormField(
              controller: _remarksController,
              decoration: InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isSubmitting ? null : _finishTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Finish Task', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/equipment_operation_provider.dart';
import '../models/equipment_operation.dart';
import 'create_operation_screen.dart';
import 'operation_details_screen.dart';

class OperationsListScreen extends StatefulWidget {
  const OperationsListScreen({super.key});

  @override
  State<OperationsListScreen> createState() => _OperationsListScreenState();
}

class _OperationsListScreenState extends State<OperationsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
      provider.loadOperations(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
      if (provider.hasMorePages && !provider.isLoadingOperations) {
        provider.loadNextPage();
      }
    }
  }

  Future<void> _onRefresh() async {
    final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
    await provider.loadOperations(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Equipment Operations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<EquipmentOperationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingOperations && provider.operations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.operationsError != null && provider.operations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load operations',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.operationsError!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.operations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No operations yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to start a new operation',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.operations.length + (provider.hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.operations.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return _OperationCard(
                  operation: provider.operations[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OperationDetailsScreen(
                          scrum: provider.operations[index].scrum,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateOperationScreen(),
            ),
          ).then((_) => _onRefresh());
        },
        icon: const Icon(Icons.add),
        label: const Text('Start New Operation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  final EquipmentOperation operation;
  final VoidCallback onTap;

  const _OperationCard({
    required this.operation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operation.equipment?.code ?? 'Unknown Equipment',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (operation.equipment?.category != null)
                          Text(
                            operation.equipment!.category!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _ShiftBadge(shift: operation.shift),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    operation.displayDate,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      operation.user?.name ?? 'Unknown',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HM: ${operation.opsHmStart.toStringAsFixed(1)}${operation.opsHmEnd != null ? ' → ${operation.opsHmEnd!.toStringAsFixed(1)}' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (operation.totalHours != null)
                          Text(
                            'Total: ${operation.totalHours!.toStringAsFixed(1)} hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusIndicator(isFinished: operation.isFinished),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftBadge extends StatelessWidget {
  final String shift;

  const _ShiftBadge({required this.shift});

  @override
  Widget build(BuildContext context) {
    final isDay = shift.toLowerCase() == 'day';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDay ? Colors.amber[600] : Colors.indigo[600],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        shift,
        style: TextStyle(
          color: isDay ? Colors.black87 : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isFinished;

  const _StatusIndicator({required this.isFinished});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isFinished ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFinished ? Colors.green[300]! : Colors.blue[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFinished ? Icons.check_circle : Icons.circle,
            size: 16,
            color: isFinished ? Colors.green[700] : Colors.blue[700],
          ),
          const SizedBox(width: 4),
          Text(
            isFinished ? 'Finished' : 'In Progress',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isFinished ? Colors.green[700] : Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }
}

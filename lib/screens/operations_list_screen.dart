import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/equipment_operation_provider.dart';
import '../models/equipment_operation.dart';
import '../models/equipment.dart';
import '../l10n/app_localizations.dart';
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
      provider.loadReferenceData();
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          l10n.equipmentOperations,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Consumer<EquipmentOperationProvider>(
            builder: (context, provider, _) {
              return Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Equipment Filter
                        Expanded(
                          child: DropdownButtonFormField<Equipment>(
                            value: provider.filterEquipment,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.filterEquipment,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            items: provider.equipment.map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.code, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) {
                              provider.setFilters(equipment: val, date: provider.filterDate);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Date Filter Button
                        IconButton(
                          icon: Icon(
                            Icons.calendar_today, 
                            color: provider.filterDate != null ? AppColors.primary : Colors.grey
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: provider.filterDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              provider.setFilters(equipment: provider.filterEquipment, date: date);
                            }
                          },
                        ),

                        // Clear Filter
                        if (provider.filterEquipment != null || provider.filterDate != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: provider.clearFilters,
                          ),
                      ],
                    ),
                    if (provider.filterDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Text(
                              '${l10n.date}: ${provider.filterDate!.toIso8601String().split('T')[0]}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<EquipmentOperationProvider>(
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
                          l10n.failedToLoadOperations,
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
                          label: Text(l10n.retry),
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
                          l10n.noOperationsFound,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
          ),
        ],
      ),
      floatingActionButton: Consumer<EquipmentOperationProvider>(
        builder: (context, provider, child) {
          // Hide button if unauthorized
          if (provider.operationsError != null && 
              (provider.operationsError!.contains('Unauthorized') || 
               provider.operationsError!.contains('403') ||
               provider.operationsError!.contains('401'))) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateOperationScreen(),
                ),
              ).then((_) => _onRefresh());
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.startNewOperation),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          );
        },
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
    final l10n = AppLocalizations.of(context)!;
    
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
                          operation.equipment?.code ?? l10n.unknownEquipment,
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
                      operation.user?.name ?? l10n.unknown,
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
                            '${l10n.total}: ${operation.totalHours!.toStringAsFixed(1)} ${l10n.hours}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusIndicator(operation: operation),
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
  final EquipmentOperation operation;

  const _StatusIndicator({
    required this.operation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    Color bgColor;
    String text;
    IconData icon;

    if (operation.isApproved) {
      color = Colors.green[700]!;
      bgColor = Colors.green[50]!;
      text = l10n.approved;
      icon = Icons.verified;
    } else if (operation.isFinished) {
      color = Colors.amber[800]!;
      bgColor = Colors.amber[50]!;
      text = l10n.finishedPending;
      icon = Icons.check_circle_outline;
    } else {
      color = Colors.blue[700]!;
      bgColor = Colors.blue[50]!;
      text = l10n.inProgress;
      icon = Icons.timelapse;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

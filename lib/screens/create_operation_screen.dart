import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../constants/app_colors.dart';
import '../providers/equipment_operation_provider.dart';
import '../models/equipment.dart';
import '../models/equipment_operation_requests.dart';
import '../l10n/app_localizations.dart';
import 'operation_details_screen.dart';

class CreateOperationScreen extends StatefulWidget {
  const CreateOperationScreen({super.key});

  @override
  State<CreateOperationScreen> createState() => _CreateOperationScreenState();
}

class _CreateOperationScreenState extends State<CreateOperationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hmStartController = TextEditingController();
  
  Equipment? _selectedEquipment;
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = '';
  File? _photoFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedShift = _getAutoShift();
    // Defer loading data until after the build to prevent "setState during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReferenceData();
    });
  }

  @override
  void dispose() {
    _hmStartController.dispose();
    super.dispose();
  }

  void _loadReferenceData() {
    final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
    provider.loadReferenceData();
  }

  String _getAutoShift() {
    final hour = DateTime.now().hour;
    return (hour >= 6 && hour < 18) ? 'Day' : 'Night';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        
        // Check file size and compress if needed (Lowered threshold for Nginx 1MB limit)
        final fileSize = await imageFile.length();
        if (fileSize > 512 * 1024) { // > 512KB
          // Compress
          final compressedFile = await _compressImage(imageFile);
          if (compressedFile != null) {
            imageFile = compressedFile;
          }
        }
        
        setState(() {
          _photoFile = imageFile;
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment')),
      );
      return;
    }

    if (_photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a start photo')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = CreateOperationRequest(
        equipmentId: _selectedEquipment!.id,
        date: _selectedDate,
        shift: _selectedShift,
        opsHmStart: double.parse(_hmStartController.text),
        photo: _photoFile!,
      );

      final provider = Provider.of<EquipmentOperationProvider>(context, listen: false);
      final operation = await provider.createOperation(request);

      if (mounted) {
        if (operation != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Operation started successfully!')),
          );
          
          // Navigate to details/tasks screen instead of list
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OperationDetailsScreen(scrum: operation.scrum),
            ),
          );
        } else {
           // Display specific backend error
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed: ${provider.operationError ?? "Unknown Error"}')),
           );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create operation: $e')),
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.startOperation),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<EquipmentOperationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingReferenceData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Equipment Dropdown or Empty Warning
                if (provider.equipment.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No equipment assigned to you.',
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<Equipment>(
                    value: _selectedEquipment,
                    decoration: InputDecoration(
                      labelText: '${l10n.equipment} *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.agriculture),
                    ),
                    items: provider.equipment.map((equipment) {
                      return DropdownMenuItem(
                        value: equipment,
                        child: Text(
                          equipment.displayName,
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    isExpanded: true, // Allow dropdown to expand to fit width
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedEquipment = value;
                        });
                        
                        // Fetch last HM
                        final lastHm = await provider.getLastHm(value.id);
                        if (lastHm != null && lastHm > 0) {
                          if (mounted) {
                            setState(() {
                              _hmStartController.text = lastHm.toStringAsFixed(2);
                            });
                          }
                        }
                      }
                    },
                    validator: (value) => value == null ? l10n.pleaseSelectEquipment : null,
                  ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '${l10n.date} *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Shift Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shift *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'Day',
                          label: Text(l10n.dayShift),
                          icon: const Icon(Icons.wb_sunny),
                        ),
                        ButtonSegment(
                          value: 'Night',
                          label: Text(l10n.nightShift),
                          icon: const Icon(Icons.nightlight),
                        ),
                      ],
                      selected: {_selectedShift},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedShift = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // HM Start
                TextFormField(
                  controller: _hmStartController,
                  decoration: InputDecoration(
                    labelText: '${l10n.hourMeterStart} *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.speed),
                    suffixText: 'HM/KM',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterHmStart;
                    }
                    final num? hmValue = double.tryParse(value);
                    if (hmValue == null || hmValue < 0) {
                      return 'Please enter a valid number >= 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Photo Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.startPhoto} *',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    if (_photoFile != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _photoFile!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _photoFile = null;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add photo',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: (_isSubmitting || provider.equipment.isEmpty) ? null : _submit,
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
                      : Text(
                          l10n.startOperation,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

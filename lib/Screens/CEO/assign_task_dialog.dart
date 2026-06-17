import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Task_model.dart';
import '../../Providers/TaskProvider.dart';

class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFF8B5CF6);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
}

class AssignTaskDialog extends StatefulWidget {
  const AssignTaskDialog({super.key});

  @override
  State<AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends State<AssignTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _priority = 'Medium';
  String _assigneeType = 'Department';
  String? _selectedDepartment;
  String? _selectedUserId;
  String? _selectedUserName;
  
  bool _isLoadingUsers = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _users = [];

  final List<String> _departments = [
    'Sales', 'Accounts', 'Operations', 'QubiQ', 'Digital Marketing', 'Content Hub', 'Testing'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _users = snap.docs.map((d) => {
          'id': d.id,
          'name': d.data()['name'] ?? 'Unknown User',
          'role': d.data()['role'] ?? 'No Role',
        }).toList();
        _users.sort((a, b) => a['name'].compareTo(b['name']));
      });
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }
    setState(() => _isLoadingUsers = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assigneeType == 'Department' && _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a department')));
      return;
    }
    if (_assigneeType == 'Person' && _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a person')));
      return;
    }

    setState(() => _isSubmitting = true);

    final task = TaskModel(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      assigneeType: _assigneeType,
      assignedToId: _assigneeType == 'Department' ? _selectedDepartment! : _selectedUserId!,
      assignedToName: _assigneeType == 'Department' ? _selectedDepartment! : _selectedUserName!,
    );

    final success = await context.read<TaskProvider>().addTask(task);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to assign task')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _C.bg.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _C.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.assignment_add, color: _C.accent),
                        ),
                        const SizedBox(width: 16),
                        const Text("Assign Work", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: _C.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // TITLE
                    _buildTextField(_titleController, "Task Title", Icons.title),
                    const SizedBox(height: 16),
                    
                    // DESCRIPTION
                    _buildTextField(_descController, "Description / Instructions", Icons.description, maxLines: 3),
                    const SizedBox(height: 24),
                    
                    // PRIORITY
                    const Text("Priority Level", style: TextStyle(color: _C.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPriorityChip('Low', Colors.green),
                        const SizedBox(width: 12),
                        _buildPriorityChip('Medium', Colors.orange),
                        const SizedBox(width: 12),
                        _buildPriorityChip('High', Colors.red),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ASSIGNEE TYPE
                    const Text("Assign To", style: TextStyle(color: _C.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTypeToggle('Department', Icons.business)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTypeToggle('Person', Icons.person)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // DROPDOWN
                    if (_assigneeType == 'Department')
                      _buildDropdown(
                        "Select Department",
                        _selectedDepartment,
                        _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Colors.white)))).toList(),
                        (v) => setState(() => _selectedDepartment = v),
                      )
                    else
                      _isLoadingUsers
                        ? const Center(child: CircularProgressIndicator(color: _C.accent))
                        : _buildDropdown(
                            "Select Person",
                            _selectedUserId,
                            _users.map((u) => DropdownMenuItem(
                              value: u['id'], 
                              child: Text("${u['name']} (${u['role']})", style: const TextStyle(color: Colors.white))
                            )).toList(),
                            (v) {
                              setState(() {
                                _selectedUserId = v as String;
                                _selectedUserName = _users.firstWhere((u) => u['id'] == v)['name'];
                              });
                            },
                          ),
                    
                    const SizedBox(height: 32),
                    
                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                            : const Text("Delegate Task", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.textMuted),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0),
          child: Icon(icon, color: _C.textSecondary, size: 20),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPriorityChip(String level, Color color) {
    final isSelected = _priority == level;
    return InkWell(
      onTap: () => setState(() => _priority = level),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Text(level, style: TextStyle(color: isSelected ? color : _C.textSecondary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTypeToggle(String type, IconData icon) {
    final isSelected = _assigneeType == type;
    return InkWell(
      onTap: () => setState(() {
        _assigneeType = type;
        _selectedDepartment = null;
        _selectedUserId = null;
      }),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? _C.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? _C.accent : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? _C.accent : _C.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(type, style: TextStyle(color: isSelected ? _C.accent : _C.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<DropdownMenuItem<dynamic>> items, Function(dynamic) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          value: value,
          hint: Text(hint, style: const TextStyle(color: _C.textMuted)),
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: _C.surface,
          icon: const Icon(Icons.keyboard_arrow_down, color: _C.textSecondary),
        ),
      ),
    );
  }
}

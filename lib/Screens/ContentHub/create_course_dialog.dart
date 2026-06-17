import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/Course.dart';

class CustomSectionState {
  final TextEditingController titleController;
  final List<TextEditingController> itemControllers;

  CustomSectionState({required this.titleController, required this.itemControllers});

  void dispose() {
    titleController.dispose();
    for (var c in itemControllers) {
      c.dispose();
    }
  }
}

class CurriculumItemState {
  final TextEditingController titleController;
  final TextEditingController typeController;
  final TextEditingController durationController;
  final TextEditingController videoUrlController;

  CurriculumItemState({
    required this.titleController,
    required this.typeController,
    required this.durationController,
    required this.videoUrlController,
  });

  void dispose() {
    titleController.dispose();
    typeController.dispose();
    durationController.dispose();
    videoUrlController.dispose();
  }
}

class CreateCourseDialog extends StatefulWidget {
  final Course? course;
  final bool isDigitalMarketer;

  const CreateCourseDialog({super.key, this.course, this.isDigitalMarketer = false});

  @override
  State<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<CreateCourseDialog> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _offerPriceController = TextEditingController();
  String _status = "Draft";

  // Standard Arrays
  final List<TextEditingController> _learningPointsControllers = [];
  final List<TextEditingController> _includedItemsControllers = [];
  final List<CurriculumItemState> _curriculumStates = [];

  // Custom Sections
  final List<CustomSectionState> _customSectionStates = [];

  // Scheduling
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  // Templates
  List<String> _availableTemplates = [];
  String? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _nameController.text = widget.course!.name;
      _descController.text = widget.course!.description;
      _categoryController.text = widget.course!.category;
      _durationController.text = widget.course!.duration;
      _priceController.text = widget.course!.price.toString();
      _offerPriceController.text = widget.course!.offerPrice?.toString() ?? '';
      _status = widget.course!.status;
      _scheduledDate = widget.course!.scheduledPublishDate;
      if (_scheduledDate != null) {
        _scheduledTime = TimeOfDay.fromDateTime(_scheduledDate!);
      }

      for (var pt in widget.course!.learningPoints) {
        _learningPointsControllers.add(TextEditingController(text: pt));
      }
      for (var it in widget.course!.includedItems) {
        _includedItemsControllers.add(TextEditingController(text: it));
      }
      for (var cur in widget.course!.curriculum) {
        _curriculumStates.add(CurriculumItemState(
          titleController: TextEditingController(text: cur.title),
          typeController: TextEditingController(text: cur.type),
          durationController: TextEditingController(text: cur.duration),
          videoUrlController: TextEditingController(text: cur.videoUrl),
        ));
      }
      for (var sec in widget.course!.customSections) {
        _customSectionStates.add(CustomSectionState(
          titleController: TextEditingController(text: sec.title),
          itemControllers: sec.items.map((e) => TextEditingController(text: e)).toList(),
        ));
      }
    }

    if (_learningPointsControllers.isEmpty) _addLearningPoint();
    if (_includedItemsControllers.isEmpty) _addIncludedItem();
    _loadAvailableTemplates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _offerPriceController.dispose();
    for (var c in _learningPointsControllers) {
      c.dispose();
    }
    for (var c in _includedItemsControllers) {
      c.dispose();
    }
    for (var s in _curriculumStates) {
      s.dispose();
    }
    for (var s in _customSectionStates) {
      s.dispose();
    }
    super.dispose();
  }

  // --- Dynamic Form Actions ---

  void _addLearningPoint() => setState(() => _learningPointsControllers.add(TextEditingController()));
  void _addIncludedItem() => setState(() => _includedItemsControllers.add(TextEditingController()));

  void _addCurriculumItem() {
    setState(() {
      _curriculumStates.add(CurriculumItemState(
        titleController: TextEditingController(),
        typeController: TextEditingController(text: "Video"),
        durationController: TextEditingController(),
        videoUrlController: TextEditingController(),
      ));
    });
  }

  void _addCustomSection() {
    setState(() {
      _customSectionStates.add(CustomSectionState(
        titleController: TextEditingController(),
        itemControllers: [TextEditingController()],
      ));
    });
  }

  void _addCustomSectionItem(CustomSectionState section) {
    setState(() {
      section.itemControllers.add(TextEditingController());
    });
  }

  // --- Template Management ---

  Future<void> _loadAvailableTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('course_template_')).toList();
    setState(() {
      _availableTemplates = keys.map((k) => k.replaceFirst('course_template_', '')).toList();
    });
  }

  Future<void> _saveAsTemplate() async {
    final name = await _showInputDialog("Template Name", "Enter a name for this template");
    if (name == null || name.isEmpty) return;

    final templateData = {
      'customSections': _customSectionStates.map((s) => {
        'title': s.titleController.text,
        'items': s.itemControllers.map((c) => c.text).toList(),
      }).toList(),
      'curriculumCount': _curriculumStates.length,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('course_template_$name', jsonEncode(templateData));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Template '$name' saved!")));
      _loadAvailableTemplates();
    }
  }

  Future<void> _loadTemplate(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('course_template_$name');
    if (dataStr == null) return;

    final data = jsonDecode(dataStr);
    
    setState(() {
      // Clear existing custom sections
      _customSectionStates.clear();
      
      // Load custom sections
      if (data['customSections'] != null) {
        for (var sec in data['customSections']) {
          final state = CustomSectionState(
            titleController: TextEditingController(text: sec['title']),
            itemControllers: (sec['items'] as List).map((i) => TextEditingController(text: i.toString())).toList(),
          );
          if (state.itemControllers.isEmpty) state.itemControllers.add(TextEditingController());
          _customSectionStates.add(state);
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Template '$name' loaded!")));
    }
  }

  Future<String?> _showInputDialog(String title, String hint) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: const Text("Save")),
        ],
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF38BDF8),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _scheduledTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF38BDF8),
                onPrimary: Colors.white,
                surface: Color(0xFF1E293B),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (time != null) {
        setState(() {
          _scheduledDate = date;
          _scheduledTime = time;
        });
      }
    }
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: 800,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 1, color: Colors.white10),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Basic Information", Icons.info_outline),
                          const SizedBox(height: 16),
                          _buildTextField("Course Title", _nameController, isRequired: true),
                          _buildTextField("Description", _descController, maxLines: 3, isRequired: true),
                          Row(
                            children: [
                              Expanded(child: _buildTextField("Category", _categoryController)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField("Duration (e.g. 10 Hours)", _durationController)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: _buildTextField("Price (in ₹)", _priceController)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField("Offer Price (optional)", _offerPriceController)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: DropdownButtonFormField<String>(
                                    value: ["Draft", "Published", "Archived", "Scheduled", "Pending SEO"].contains(_status) ? _status : "Draft",
                                    dropdownColor: const Color(0xFF1E293B),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration("Status"),
                                    items: ["Draft", "Published", "Archived", "Scheduled", "Pending SEO"]
                                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _status = v!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Spacer(),
                            ],
                          ),

                          const SizedBox(height: 16),
                          if (_status == "Scheduled")
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: _selectDateTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month, color: Color(0xFF38BDF8)),
                                      const SizedBox(width: 12),
                                      Text(
                                        _scheduledDate != null && _scheduledTime != null
                                            ? "Scheduled for: ${_scheduledDate!.toLocal().toString().split(' ')[0]} at ${_scheduledTime!.format(context)}"
                                            : "Select Publish Date & Time",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),
                          _buildSectionTitleWithAdd("Learning Points", Icons.lightbulb_outline, _addLearningPoint),
                          ..._buildDynamicList(_learningPointsControllers, "Point"),

                          const SizedBox(height: 32),
                          _buildSectionTitleWithAdd("Included Items", Icons.inventory_2_outlined, _addIncludedItem),
                          ..._buildDynamicList(_includedItemsControllers, "Item"),

                          const SizedBox(height: 32),
                          _buildSectionTitleWithAdd("Curriculum", Icons.menu_book_rounded, _addCurriculumItem),
                          ..._buildCurriculumStates(),

                          const SizedBox(height: 32),
                          _buildSectionTitleWithAdd("Custom Sections", Icons.dashboard_customize_outlined, _addCustomSection),
                          const SizedBox(height: 8),
                          Text("Add custom sections like 'Prerequisites', 'Target Audience', or 'Resources'.", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                          const SizedBox(height: 16),
                          ..._buildCustomSections(),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8).withOpacity(0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF38BDF8).withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.school_rounded, color: Color(0xFF38BDF8), size: 24),
          ),
          const SizedBox(width: 16),
          Text(widget.course == null ? "Create Advanced Course" : "Edit Course", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (_availableTemplates.isNotEmpty)
            DropdownButton<String>(
              hint: Text("Load Template", style: TextStyle(color: Colors.white.withOpacity(0.7))),
              value: _selectedTemplate,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              items: _availableTemplates.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedTemplate = v);
                  _loadTemplate(v);
                }
              },
            ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _saveAsTemplate,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text("Save Template"),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF38BDF8)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _saveCourse([String? overrideStatus]) {
    if (_formKey.currentState!.validate()) {
      final finalStatus = overrideStatus ?? _status;
      
      if (finalStatus == "Scheduled" && (_scheduledDate == null || _scheduledTime == null)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a date and time for scheduling.")));
        return;
      }

      DateTime? finalPublishDate;
      if (finalStatus == "Scheduled" && _scheduledDate != null && _scheduledTime != null) {
        finalPublishDate = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );
      }

      final course = Course(
        id: widget.course?.id ?? '',
        name: _nameController.text,
        description: _descController.text,
        category: _categoryController.text,
        duration: _durationController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        offerPrice: double.tryParse(_offerPriceController.text),
        status: finalStatus,
        scheduledPublishDate: finalPublishDate,
        learningPoints: _learningPointsControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList(),
        includedItems: _includedItemsControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList(),
        curriculum: _curriculumStates.map((s) => CurriculumItem(
          title: s.titleController.text,
          type: s.typeController.text,
          duration: s.durationController.text,
          videoUrl: s.videoUrlController.text,
        )).toList(),
        customSections: _customSectionStates.map((s) => CustomSection(
          title: s.titleController.text,
          items: s.itemControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList(),
        )).toList(),
      );
      Navigator.pop(context, course);
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text("Cancel"),
          ),
          const SizedBox(width: 12),
          if (widget.isDigitalMarketer)
            ElevatedButton(
              onPressed: () => _saveCourse("Published"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Update Server", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else ...[
            ElevatedButton(
              onPressed: () => _saveCourse("Pending SEO"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Send for SEO", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _saveCourse("Published"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Publish", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (widget.course != null) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _saveCourse(), // Uses dropdown status
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64748B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]
          ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildSectionTitleWithAdd(String title, IconData icon, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(title, icon),
        InkWell(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, size: 16, color: Color(0xFF38BDF8)),
                SizedBox(width: 4),
                Text("Add", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label),
        validator: isRequired ? (v) => v == null || v.isEmpty ? "Required field" : null : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      filled: true,
      fillColor: const Color(0xFF1E293B).withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
    );
  }

  List<Widget> _buildDynamicList(List<TextEditingController> controllers, String hint) {
    return controllers.asMap().entries.map((entry) {
      int idx = entry.key;
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: entry.value,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("$hint ${idx + 1}"),
              ),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
              onPressed: () => setState(() => controllers.removeAt(idx)),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildCurriculumStates() {
    return _curriculumStates.asMap().entries.map((entry) {
      int idx = entry.key;
      final state = entry.value;
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Lesson ${idx + 1}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                  onPressed: () => setState(() => _curriculumStates.removeAt(idx)),
                ),
              ],
            ),
            _buildTextField("Lesson Title", state.titleController),
            Row(
              children: [
                Expanded(child: _buildTextField("Type (Video/Quiz/PDF)", state.typeController)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Duration (e.g. 10m)", state.durationController)),
              ],
            ),
            _buildTextField("Video URL (optional)", state.videoUrlController),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildCustomSections() {
    return _customSectionStates.asMap().entries.map((entry) {
      int idx = entry.key;
      final state = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFF38BDF8).withOpacity(0.05), Colors.transparent]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: state.titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Section Title (e.g. Prerequisites)",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () => setState(() => _customSectionStates.removeAt(idx)),
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            ...state.itemControllers.asMap().entries.map((itemEntry) {
              int itemIdx = itemEntry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: itemEntry.value,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Item ${itemIdx + 1}",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white.withOpacity(0.3), size: 18),
                      onPressed: () => setState(() => state.itemControllers.removeAt(itemIdx)),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => _addCustomSectionItem(state),
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add Item"),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF38BDF8)),
            ),
          ],
        ),
      );
    }).toList();
  }
}

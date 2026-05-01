import 'package:flutter/material.dart';
import '../../Model/Course.dart';

class CreateCourseDialog extends StatefulWidget {
  const CreateCourseDialog({super.key});

  @override
  State<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<CreateCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _languageController = TextEditingController(text: "English");
  String _level = "Beginner";

  final List<TextEditingController> _learningPointControllers = [];
  final List<TextEditingController> _includedItemControllers = [];
  final List<CurriculumItemRow> _curriculumItems = [];

  @override
  void initState() {
    super.initState();
    _addLearningPoint();
    _addIncludedItem();
    _addCurriculumItem();
  }

  void _addLearningPoint() {
    setState(() => _learningPointControllers.add(TextEditingController()));
  }

  void _addIncludedItem() {
    setState(() => _includedItemControllers.add(TextEditingController()));
  }

  void _addCurriculumItem() {
    setState(() => _curriculumItems.add(CurriculumItemRow()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _languageController.dispose();
    for (var c in _learningPointControllers) {
      c.dispose();
    }
    for (var c in _includedItemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget resolve(BuildContext context) {
    return AlertDialog(
      title: const Text("Create New Course"),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Basic Information"),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Course Name"),
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 2,
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        decoration:
                            const InputDecoration(labelText: "Category"),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _level,
                        decoration: const InputDecoration(labelText: "Level"),
                        items: ["Beginner", "Intermediate", "Advanced"]
                            .map((l) =>
                                DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) => setState(() => _level = v!),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration:
                            const InputDecoration(labelText: "Duration"),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _languageController,
                        decoration:
                            const InputDecoration(labelText: "Language"),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null
                      ? "Valid price required"
                      : null,
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration:
                      const InputDecoration(labelText: "Banner Image URL"),
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 24),
                _sectionTitleWithAdd("What You Will Learn", _addLearningPoint),
                ..._buildDynamicList(_learningPointControllers, "Point"),
                const SizedBox(height: 24),
                _sectionTitleWithAdd("What's Included", _addIncludedItem),
                ..._buildDynamicList(_includedItemControllers, "Item"),
                const SizedBox(height: 24),
                _sectionTitleWithAdd("Course Curriculum", _addCurriculumItem),
                ..._buildCurriculumList(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final course = Course(
                id: '',
                name: _nameController.text,
                description: _descController.text,
                category: _categoryController.text,
                duration: _durationController.text,
                price: double.parse(_priceController.text),
                imageUrl: _imageUrlController.text,
                level: _level,
                language: _languageController.text,
                learningPoints: _learningPointControllers
                    .map((c) => c.text)
                    .where((t) => t.isNotEmpty)
                    .toList(),
                includedItems: _includedItemControllers
                    .map((c) => c.text)
                    .where((t) => t.isNotEmpty)
                    .toList(),
                curriculum: _curriculumItems
                    .map((r) => r.toItem())
                    .where((i) => i.title.isNotEmpty)
                    .toList(),
              );
              Navigator.pop(context, course);
            }
          },
          child: const Text("Create Course"),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  Widget _sectionTitleWithAdd(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
            onPressed: onAdd),
      ],
    );
  }

  List<Widget> _buildDynamicList(
      List<TextEditingController> controllers, String hint) {
    return controllers.asMap().entries.map((entry) {
      int idx = entry.key;
      var controller = entry.value;
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(hintText: "$hint ${idx + 1}"),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => setState(() => controllers.removeAt(idx)),
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildCurriculumList() {
    return _curriculumItems.asMap().entries.map((entry) {
      int idx = entry.key;
      var row = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Expanded(
                flex: 3,
                child: TextFormField(
                    controller: row.titleController,
                    decoration: const InputDecoration(hintText: "Title"))),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: row.type,
                items: ["Video", "Assessment", "Reading"]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => row.type = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
                flex: 2,
                child: TextFormField(
                    controller: row.durationController,
                    decoration: const InputDecoration(hintText: "Duration"))),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () {
                setState(() => _curriculumItems.removeAt(idx));
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) => resolve(context);
}

class CurriculumItemRow {
  final titleController = TextEditingController();
  final durationController = TextEditingController();
  String type = "Video";

  CurriculumItem toItem() {
    return CurriculumItem(
      title: titleController.text,
      type: type,
      duration: durationController.text,
    );
  }
}

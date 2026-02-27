import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Qubiq/QubiqProvider.dart';

class SearchSchoolDialog extends StatefulWidget {
  const SearchSchoolDialog({super.key});

  @override
  State<SearchSchoolDialog> createState() => _SearchSchoolDialogState();
}

class _SearchSchoolDialogState extends State<SearchSchoolDialog> {
  final _searchCtrl = TextEditingController();
  List<SchoolVisit> _results = [];
  bool _searching = false;

  void _onSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);

    final results = await context.read<QubiqProvider>().searchSchools(query);

    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Search School"),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: "Enter school name or city",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _onSearch,
                  icon: const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? const Center(child: Text("No results found"))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final school = _results[index];
                            return ListTile(
                              title: Text(school.schoolProfile.name),
                              subtitle: Text(
                                  "${school.schoolProfile.city}, ${school.schoolProfile.state}"),
                              leading: const Icon(Icons.school,
                                  color: Colors.blueGrey),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () {
                                context
                                    .read<QubiqProvider>()
                                    .addManualSchool(school);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Added ${school.schoolProfile.name} to list")),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}

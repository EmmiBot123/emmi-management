import 'package:flutter/material.dart';
import '../../../../../Model/Marketing/ProductRequest.dart';

class SerialGeneratorPage extends StatefulWidget {
  final List<ProductRequest> products;
  final Map<String, TextEditingController> formatControllers;
  final Map<String, List<String>> productSerialMap;
  final bool serialSaved;
  final VoidCallback onSave;
  final String Function(String) normalizeKey;

  const SerialGeneratorPage({
    super.key,
    required this.products,
    required this.formatControllers,
    required this.productSerialMap,
    required this.serialSaved,
    required this.onSave,
    required this.normalizeKey,
  });

  @override
  State<SerialGeneratorPage> createState() => _SerialGeneratorPageState();
}

class _SerialGeneratorPageState extends State<SerialGeneratorPage> {
  static const String defaultFormat = "PRSSSYYMMSTCT###";

  String generateSerial(int index, ProductRequest p, String format) {
    final now = DateTime.now();
    final yy = now.year.toString().substring(2);
    final mm = now.month.toString().padLeft(2, '0');
    final count = (index + 1).toString().padLeft(3, '0');

    final fmt = format.isEmpty ? defaultFormat : format;

    return fmt
        .replaceAll("YY", yy)
        .replaceAll("MM", mm)
        .replaceAll("###", count);
  }

  void resetFormat(String key, ProductRequest p) {
    setState(() {
      widget.formatControllers[key]!.text = defaultFormat;

      final qty = p.quantity;

      widget.productSerialMap[key] = List.generate(
        qty,
        (i) => generateSerial(i, p, defaultFormat),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Restored to default format")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Serial Generator")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...widget.products.map((p) {
            final key = widget.normalizeKey(p.name);
            final controller = widget.formatControllers[key]!;

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 8),

                  /// -------- FORMAT + RESET BUTTON --------
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: "Serial Format",
                            border: OutlineInputBorder(),
                            helperText: "Tokens: PR, SSS, ST, CT, YY, MM, ###",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (controller.text != defaultFormat)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey),
                          onPressed: () => resetFormat(key, p),
                          child: const Text("Reset"),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code),
                    label: Text(widget.serialSaved ? "Regenerate" : "Generate"),
                    onPressed: () {
                      final qty = p.quantity;
                      setState(() {
                        widget.productSerialMap[key] = List.generate(
                          qty,
                          (i) => generateSerial(
                            i,
                            p,
                            controller.text,
                          ),
                        );
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  if (widget.productSerialMap[key]!.isNotEmpty)
                    ...widget.productSerialMap[key]!
                        .asMap()
                        .entries
                        .map((e) => Card(
                              child: ListTile(
                                leading: Text(
                                  (e.key + 1).toString().padLeft(2, "0"),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                title: Text(e.value),
                              ),
                            ))
                ],
              ),
            );
          }),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save"),
            onPressed: widget.onSave,
          )
        ],
      ),
    );
  }
}

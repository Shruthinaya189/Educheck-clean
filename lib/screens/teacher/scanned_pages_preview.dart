import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class ScannedPagesPreview extends StatefulWidget {
  final List<String> scannedPages;
  final String studentName;
  final String testName;
  const ScannedPagesPreview({super.key, required this.scannedPages, required this.studentName, required this.testName});

  @override
  State<ScannedPagesPreview> createState() => _ScannedPagesPreviewState();
}

class _ScannedPagesPreviewState extends State<ScannedPagesPreview> {
  late List<String> _pages;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pages = List.of(widget.scannedPages);
  }

  void _delete(int i) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning_amber, color: Colors.orange), SizedBox(width: 8), Text('Delete Page')]),
        content: Text('Delete page ${i + 1}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _pages.removeAt(i));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePdf() async {
    if (_pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pages to save')));
      return;
    }
    setState(() => _saving = true);
    try {
      final doc = pw.Document();
      for (final p in _pages) {
        final img = pw.MemoryImage(await File(p).readAsBytes());
        doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (_) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain))));
      }
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/answer_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await f.writeAsBytes(await doc.save());
      if (mounted) Navigator.pop(context, f.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.studentName),
          Text('${_pages.length} page${_pages.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12)),
        ]),
        actions: [
          if (!_saving) IconButton(icon: const Icon(Icons.refresh), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: _pages.isEmpty
          ? const Center(child: Text('No pages scanned'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: .7),
              itemBuilder: (_, i) => Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Stack(
                  children: [
                    Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_pages[i]), fit: BoxFit.cover))),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                        child: Text('Page ${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                    Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(i))),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _saving ? null : () => Navigator.pop(context, _pages), icon: const Icon(Icons.camera_alt), label: const Text('Scan More'))),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _savePdf,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save PDF'),
            ),
          ),
        ]),
      ),
    );
  }
}

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'scanned_pages_preview.dart';

class AnswerSheetScanner extends StatefulWidget {
  final String studentName;
  final String testName;
  const AnswerSheetScanner({super.key, required this.studentName, required this.testName});

  @override
  State<AnswerSheetScanner> createState() => _AnswerSheetScannerState();
}

class _AnswerSheetScannerState extends State<AnswerSheetScanner> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final List<String> _pages = [];
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) return;
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;
    _controller = CameraController(_cameras!.first, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  Future<void> _capture() async {
    if (!_ready || _busy) return;
    setState(() => _busy = true);
    try {
      final shot = await _controller!.takePicture();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(shot.path).copy(file.path);
      setState(() => _pages.add(file.path));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Captured page ${_pages.length}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview() async {
    if (_pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pages scanned')));
      return;
    }
    final res = await Navigator.push<List<String>?>(
      context,
      MaterialPageRoute(
        builder: (_) => ScannedPagesPreview(
          scannedPages: _pages,
          studentName: widget.studentName,
          testName: widget.testName,
        ),
      ),
    );
    if (res != null && mounted) setState(() => _pages
      ..clear()
      ..addAll(res));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.studentName),
            Text(widget.testName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (_pages.isNotEmpty)
            TextButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.preview, color: Colors.white),
              label: Text('${_pages.length}', style: const TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Positioned.fill(child: CustomPaint(painter: _Guides())),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                          child: Text('${_pages.length} page${_pages.length == 1 ? '' : 's'} scanned', style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_pages.isNotEmpty)
                              _action(Icons.preview, 'Preview', _preview, Colors.orange),
                            GestureDetector(
                              onTap: _busy ? null : _capture,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), color: _busy ? Colors.grey : Colors.white),
                                child: _busy ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 3)) : const Icon(Icons.camera_alt, size: 40, color: Colors.black),
                              ),
                            ),
                            if (_pages.isNotEmpty)
                              _action(Icons.check_circle, 'Done', () => Navigator.pop(context, _pages), Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _action(IconData i, String t, VoidCallback onTap, Color c) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: c, shape: BoxShape.circle), child: Icon(i, color: Colors.white)),
            const SizedBox(height: 6),
            Text(t, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
}

class _Guides extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white..strokeWidth = 3..style = PaintingStyle.stroke;
    final r = Rect.fromLTRB(size.width * .1, size.height * .2, size.width * .9, size.height * .7);
    const L = 40.0;
    // TL
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + L, r.top), p);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left, r.top + L), p);
    // TR
    canvas.drawLine(Offset(r.right - L, r.top), Offset(r.right, r.top), p);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + L), p);
    // BL
    canvas.drawLine(Offset(r.left, r.bottom - L), Offset(r.left, r.bottom), p);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + L, r.bottom), p);
    // BR
    canvas.drawLine(Offset(r.right - L, r.bottom), Offset(r.right, r.bottom), p);
    canvas.drawLine(Offset(r.right, r.bottom - L), Offset(r.right, r.bottom), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

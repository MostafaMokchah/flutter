// For mobile:
import 'dart:io' show File;

// Flutter foundation:
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

// Mobile-only PDF view:
import 'package:flutter_pdfview/flutter_pdfview.dart' show PDFView;

// Web-only PDF view (your own widget):
import 'package:mon_sirh_mobile/widgets/pdf_web_viewer.dart' show PdfWebViewer;

// path_provider only for mobile (no web support)
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String? pdfUrl;
  final String? pdfPath;
  final String title;

  const PdfViewerScreen({
    super.key,
    this.pdfUrl,
    this.pdfPath,
    required this.title,
  }) : assert(pdfUrl != null || pdfPath != null, 'Either pdfUrl or pdfPath must be provided');

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // On web, just use URL directly
      if (widget.pdfUrl != null) {
        setState(() {
          _localPath = widget.pdfUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Web: No PDF URL provided.';
          _isLoading = false;
        });
      }
    } else {
      if (widget.pdfPath != null) {
        setState(() {
          _localPath = widget.pdfPath;
          _isLoading = false;
        });
      } else if (widget.pdfUrl != null) {
        _downloadFile(widget.pdfUrl!);
      } else {
        setState(() {
          _errorMessage = "No PDF source provided.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadFile(String url) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(url).split('?').first;
        final file = File(p.join(dir.path, fileName));
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF: Status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error downloading PDF: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _localPath == null
                  ? const Center(child: Text('PDF path is null.'))
                  : kIsWeb
                      ? PdfWebViewer(url: _localPath!)
                      : PDFView(filePath: _localPath!),
    );
  }
}

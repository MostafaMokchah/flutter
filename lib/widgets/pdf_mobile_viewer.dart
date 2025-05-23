import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/material.dart';

class PdfViewerWidget extends StatelessWidget {
  final String filePath;
  const PdfViewerWidget({required this.filePath, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PDFView(filePath: filePath);
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class VisorPDFScreen extends StatefulWidget {
  final String url;
  final String nombreArchivo;

  const VisorPDFScreen({
    Key? key,
    required this.url,
    required this.nombreArchivo,
  }) : super(key: key);

  @override
  State<VisorPDFScreen> createState() => _VisorPDFScreenState();
}

class _VisorPDFScreenState extends State<VisorPDFScreen> {
  String? rutaPDFLocal;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _descargarPDF();
  }

  Future<void> _descargarPDF() async {
    try {
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/${widget.nombreArchivo}.pdf");
        await file.writeAsBytes(response.bodyBytes, flush: true);

        setState(() {
          rutaPDFLocal = file.path;
          cargando = false;
        });
      } else {
        throw Exception("Error al descargar el PDF");
      }
    } catch (e) {
      setState(() {
        cargando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo abrir el documento: $e")),
      );
    }
  }

  Future<void> _compartirPDF() async {
    if (rutaPDFLocal != null && File(rutaPDFLocal!).existsSync()) {
      await Share.shareXFiles(
        [XFile(rutaPDFLocal!)],
        text: 'Documento del producto: ${widget.nombreArchivo}',
      );
    }
  }

  Future<void> _guardarPDF() async {
    if (rutaPDFLocal == null) return;

    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final fileDestino =
          File("${downloadsDir.path}/${widget.nombreArchivo}.pdf");

      await File(rutaPDFLocal!).copy(fileDestino.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF guardado en Descargas")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar el PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreArchivo),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (!cargando && rutaPDFLocal != null)
            IconButton(
              tooltip: "Compartir PDF",
              icon: const Icon(Icons.share),
              onPressed: _compartirPDF,
            ),
          if (!cargando && rutaPDFLocal != null)
            IconButton(
              tooltip: "Guardar PDF",
              icon: const Icon(Icons.download),
              onPressed: _guardarPDF,
            ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : rutaPDFLocal != null
              ? PDFView(
                  filePath: rutaPDFLocal!,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: true,
                  pageSnap: true,
                )
              : const Center(child: Text("Error al cargar el PDF")),
    );
  }
}

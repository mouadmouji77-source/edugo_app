import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/models/exam.dart';

class ExamPreview extends StatelessWidget {
  final Exam exam;
  final VoidCallback onBack;

  const ExamPreview({
    super.key,
    required this.exam,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top action bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to form',
              ),
              const SizedBox(width: 8),
              Text(
                'Exam Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _printExam(context),
                icon: const Icon(Icons.print),
                label: const Text('Print'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _downloadPdf(context),
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
              ),
            ],
          ),
        ),

        // Preview area
        Expanded(
          child: Container(
            color: Colors.grey[300],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  width: 595, // A4 width in points at 72 dpi
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildExamPreview(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with logos and school name
          _buildHeader(context),
          const SizedBox(height: 24),
          
          // Divider
          Container(height: 2, color: Colors.black),
          const SizedBox(height: 16),
          
          // Student info fields
          _buildStudentInfo(context),
          const SizedBox(height: 24),
          
          // Exam info
          _buildExamInfo(context),
          const SizedBox(height: 24),
          
          // Questions
          ...exam.questions.asMap().entries.map((entry) {
            return _buildQuestion(context, entry.key + 1, entry.value);
          }),
          
          const SizedBox(height: 32),
          
          // Footer
          Container(height: 1, color: Colors.grey),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Good Luck!',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left logo (bigger)
        if (exam.logoBase64 != null)
          _buildLogo()
        else
          const SizedBox(width: 120, height: 120),
        
        const SizedBox(width: 16),
        
        // School name and exam title (center)
        Expanded(
          child: Column(
            children: [
              Text(
                exam.schoolName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                exam.examTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    if (exam.logoBase64 == null) return const SizedBox.shrink();
    
    try {
      final bytes = base64Decode(exam.logoBase64!);
      return Image.memory(
        bytes,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      );
    } catch (e) {
      return const SizedBox(width: 120, height: 120);
    }
  }

  Widget _buildStudentInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Nom: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.black,
                  margin: const EdgeInsets.only(top: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Prénom: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.black,
                  margin: const EdgeInsets.only(top: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Date: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.black,
                  margin: const EdgeInsets.only(top: 16),
                ),
              ),
              const SizedBox(width: 32),
              const Text(
                'Classe: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.black,
                  margin: const EdgeInsets.only(top: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${exam.questions.length} Questions',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue),
          ),
          child: Text(
            'Total: ${exam.totalPoints.toStringAsFixed(0)} points',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, int number, ExamQuestion question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Q$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${question.points.toStringAsFixed(1)} pts',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Answer lines (2 lines)
          ...List.generate(2, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 1,
              color: Colors.black54,
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final pdf = await _generatePdf();
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${exam.schoolName.replaceAll(' ', '_')}_Exam.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printExam(BuildContext context) async {
    try {
      final pdf = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    
    pw.MemoryImage? logoImage;
    if (exam.logoBase64 != null) {
      try {
        final bytes = base64Decode(exam.logoBase64!);
        logoImage = pw.MemoryImage(bytes);
      } catch (e) {
        // Ignore logo errors
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(logoImage),
        footer: (context) => pw.Center(
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        build: (context) => [
          // Student info
          _buildPdfStudentInfo(),
          pw.SizedBox(height: 20),
          
          // Exam info
          _buildPdfExamInfo(),
          pw.SizedBox(height: 20),
          
          // Questions
          ...exam.questions.asMap().entries.map((entry) {
            return _buildPdfQuestion(entry.key + 1, entry.value);
          }),
          
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text(
              'Good Luck!',
              style: pw.TextStyle(
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfHeader(pw.MemoryImage? logoImage) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left logo (bigger)
            if (logoImage != null)
              pw.Image(logoImage, width: 110, height: 110)
            else
              pw.SizedBox(width: 110, height: 110),
            
            pw.SizedBox(width: 12),
            
            // School name and exam title
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    exam.schoolName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    exam.examTitle,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2, color: PdfColors.black),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildPdfStudentInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Text('Nom: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.Expanded(child: pw.Divider(color: PdfColors.black)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Text('Prénom: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.Expanded(child: pw.Divider(color: PdfColors.black)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Text('Date: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.Expanded(child: pw.Divider(color: PdfColors.black)),
              pw.SizedBox(width: 20),
              pw.Text('Classe: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.Expanded(child: pw.Divider(color: PdfColors.black)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfExamInfo() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '${exam.questions.length} Questions',
          style: const pw.TextStyle(fontSize: 11),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
          ),
          child: pw.Text(
            'Total: ${exam.totalPoints.toStringAsFixed(0)} points',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfQuestion(int number, ExamQuestion question) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.black,
                ),
                child: pw.Text(
                  'Q$number',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Text(
                  '${question.points.toStringAsFixed(1)} pts',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            question.question,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.black,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(height: 12),
          // Answer lines (2 lines)
          ...List.generate(2, (index) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Divider(color: PdfColors.grey600, thickness: 0.5),
          )),
        ],
      ),
    );
  }
}


import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/publication.dart';
import '../models/journal_stats.dart';

class PdfGenerator {
  static Future<Uint8List> generateReport({
    required String topic,
    required int totalPublications,
    required double avgCitations,
    required int mostActiveYear,
    required List<JournalStats> topJournals,
    required List<Publication> topPublications,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TrendAnalyzer Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateTime.now().toString().substring(0, 10),
                      style: const pw.TextStyle(color: PdfColors.grey)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Topic title
            pw.Text('Research Trend Analysis for Topic: "$topic"',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue)),
            pw.SizedBox(height: 15),

            // Summary Stats Cards
            pw.Text('Summary Statistics',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Metric', 'Value'],
              data: [
                ['Total Publications Analyzed', '$totalPublications'],
                ['Average Citations per Paper', avgCitations.toStringAsFixed(2)],
                ['Most Active Publication Year', '$mostActiveYear'],
              ],
            ),
            pw.SizedBox(height: 25),

            // Top Journals Table
            if (topJournals.isNotEmpty) ...[
              pw.Text('Top Contributing Journals',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: [
                  'Journal Name',
                  'Papers',
                  'Total Citations',
                  'Avg Citations'
                ],
                data: topJournals.take(5).map((j) {
                  // Clean name to prevent PDF encoding issues
                  final cleanName =
                      j.name.replaceAll(RegExp(r'[^\x00-\x7F]'), '?');
                  return [
                    cleanName,
                    '${j.publicationCount}',
                    '${j.totalCitations}',
                    j.avgCitations.toStringAsFixed(1),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 25),
            ],

            // Top Publications List
            if (topPublications.isNotEmpty) ...[
              pw.Text('Top Influential Publications',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...topPublications.take(5).map((p) {
                final cleanTitle =
                    p.title.replaceAll(RegExp(r'[^\x00-\x7F]'), '?');
                final cleanJournal = (p.journalName ?? 'N/A')
                    .replaceAll(RegExp(r'[^\x00-\x7F]'), '?');
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Bullet(
                    text:
                        '$cleanTitle (${p.year})\nCitations: ${p.citationCount} | Journal: $cleanJournal',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                );
              }),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }
}

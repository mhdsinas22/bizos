import 'dart:io';
import 'dart:typed_data';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/pdf_generator.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class BusinessReportPreviewScreen extends StatefulWidget {
  final BusinessModel business;
  final Uint8List pdfBytes;
  final String reportTitle;
  final List<IncomeModel> incomes;
  final List<ExpenseModel> expenses;

  const BusinessReportPreviewScreen({
    super.key,
    required this.business,
    required this.pdfBytes,
    required this.reportTitle,
    required this.incomes,
    required this.expenses,
  });

  @override
  State<BusinessReportPreviewScreen> createState() =>
      _BusinessReportPreviewScreenState();
}

class _BusinessReportPreviewScreenState
    extends State<BusinessReportPreviewScreen> {
  bool _isExporting = false;

  Future<void> _handleDownloadPdf() async {
    setState(() => _isExporting = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = widget.business.name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = '${sanitizedName}_${widget.reportTitle.replaceAll(' ', '_')}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(widget.pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved successfully to ${file.path}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportExcel() async {
    setState(() => _isExporting = true);
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final buffer = StringBuffer();
      buffer.writeln('BIZOS ERP ENTERPRISE BUSINESS REPORT');
      buffer.writeln('Business Name:,${widget.business.name}');
      buffer.writeln('Report Type:,${widget.reportTitle}');
      buffer.writeln('Generated:,${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}');
      buffer.writeln('');
      buffer.writeln('Date,Type,Description,Category,Payment Method,Amount');

      for (final i in widget.incomes) {
        final desc = (i.createdByName ?? i.description).replaceAll(',', ' ');
        buffer.writeln('${dateFormat.format(i.date)},INCOME,"$desc",${i.category},${i.paymentMethod},${i.amount}');
      }
      for (final e in widget.expenses) {
        final desc = (e.createdByName ?? e.description).replaceAll(',', ' ');
        buffer.writeln('${dateFormat.format(e.date)},EXPENSE,"$desc",${e.category},${e.paymentMethod},${e.amount}');
      }

      final dir = await getTemporaryDirectory();
      final sanitizedName = widget.business.name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = '${sanitizedName}_${widget.reportTitle.replaceAll(' ', '_')}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());

      final xFile = XFile(file.path, mimeType: 'text/csv');
      await SharePlus.instance.share(
        ShareParams(files: [xFile], text: '${widget.business.name} ${widget.reportTitle} (CSV Export)'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting Excel/CSV: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handlePrint() async {
    final sanitizedName = widget.business.name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final fileName = '${sanitizedName}_${widget.reportTitle.replaceAll(' ', '_')}.pdf';
    await PdfGenerator.printPdf(widget.pdfBytes, fileName);
  }

  Future<void> _handleShare() async {
    final sanitizedName = widget.business.name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final fileName = '${sanitizedName}_${widget.reportTitle.replaceAll(' ', '_')}.pdf';
    await PdfGenerator.sharePdf(widget.pdfBytes, fileName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.reportTitle),
            Text(
              widget.business.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Report',
            onPressed: _handleShare,
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print Report',
            onPressed: _handlePrint,
          ),
        ],
      ),
      body: Stack(
        children: [
          PdfPreview(
            build: (format) => widget.pdfBytes,
            allowSharing: false,
            allowPrinting: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: '${widget.business.name}_${widget.reportTitle}.pdf',
          ),
          if (_isExporting)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleExportExcel,
                  icon: const Icon(Icons.table_chart_outlined, color: AppTheme.success, size: 18),
                  label: const Text('Export Excel', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.success),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleDownloadPdf,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

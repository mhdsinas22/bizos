import 'package:flutter/material.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';

class InvoiceLivePreviewWidget extends StatelessWidget {
  final InvoiceSettingsEntity settings;
  final String? sampleCustomerName;
  final double? sampleTotal;

  const InvoiceLivePreviewWidget({
    super.key,
    required this.settings,
    this.sampleCustomerName,
    this.sampleTotal,
  });

  Color _parseColor(String hexString) {
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _parseColor(settings.primaryColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final template = settings.template.toLowerCase();

    final String bizName = settings.businessName.isNotEmpty
        ? settings.businessName
        : 'Your Business Name';
    final String bizPhone = settings.businessPhone;
    final String bizEmail = settings.businessEmail;
    final String bizAddress = settings.businessAddress;
    final String bizGstin = settings.gstin;

    final double totalAmount = sampleTotal ?? 10000.0;
    final double taxAmount = settings.showTax ? (totalAmount * 0.18) : 0.0;
    final double grandTotal = totalAmount + taxAmount;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Render layout based on template type
          if (template == 'classic')
            _buildClassicHeader(
              context,
              primaryColor,
              isDark,
              bizName,
              bizPhone,
              bizEmail,
              bizAddress,
              bizGstin,
            )
          else if (template == 'minimal')
            _buildMinimalHeader(
              context,
              primaryColor,
              isDark,
              bizName,
              bizPhone,
              bizEmail,
              bizAddress,
              bizGstin,
            )
          else if (template == 'professional')
            _buildProfessionalHeader(
              context,
              primaryColor,
              isDark,
              bizName,
              bizPhone,
              bizEmail,
              bizAddress,
              bizGstin,
            )
          else
            _buildModernHeader(
              context,
              primaryColor,
              isDark,
              bizName,
              bizPhone,
              bizEmail,
              bizAddress,
              bizGstin,
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer & Invoice Metadata Box
                _buildCustomerMetaBox(context, primaryColor, isDark, bizGstin),
                const SizedBox(height: 16),

                // Table Header
                _buildItemsTableHeader(primaryColor, isDark, template),
                const SizedBox(height: 6),

                // Sample Line Items
                _buildItemRow(
                  'Professional Service / Product A',
                  '2',
                  '₹4,000.00',
                  '₹8,000.00',
                  isDark,
                ),
                const SizedBox(height: 4),
                _buildItemRow(
                  'Consultation & Setup Fee B',
                  '1',
                  '₹2,000.00',
                  '₹2,000.00',
                  isDark,
                ),
                const Divider(height: 20),

                // Totals Breakdown Box
                _buildTotalsBreakdown(
                  primaryColor,
                  isDark,
                  totalAmount,
                  taxAmount,
                  grandTotal,
                ),
                const SizedBox(height: 16),

                // Payment Instructions
                if (settings.paymentInstructions.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Payment Instructions:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settings.paymentInstructions,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Footer Text
                if (settings.footerText.isNotEmpty)
                  Center(
                    child: Text(
                      settings.footerText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern Template Header
  Widget _buildModernHeader(
    BuildContext context,
    Color primaryColor,
    bool isDark,
    String bizName,
    String bizPhone,
    String bizEmail,
    String bizAddress,
    String bizGstin,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (settings.showLogo &&
                    settings.logoUrl.trim().isNotEmpty) ...[
                  Container(
                    height: 44,
                    width: 100,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Image.network(
                      settings.logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
                Text(
                  bizName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                if (bizPhone.isNotEmpty)
                  Text(
                    'Ph: $bizPhone',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                if (bizEmail.isNotEmpty)
                  Text(
                    bizEmail,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                if (bizAddress.isNotEmpty)
                  Text(
                    bizAddress,
                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                    maxLines: 2,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TAX INVOICE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${settings.invoicePrefix}0001',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Classic Template Header
  Widget _buildClassicHeader(
    BuildContext context,
    Color primaryColor,
    bool isDark,
    String bizName,
    String bizPhone,
    String bizEmail,
    String bizAddress,
    String bizGstin,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryColor, width: 3)),
      ),
      child: Column(
        children: [
          if (settings.showLogo && settings.logoUrl.trim().isNotEmpty) ...[
            Center(
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 8),
                child: Image.network(
                  settings.logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          Text(
            bizName.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.5,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          if (bizPhone.isNotEmpty || bizEmail.isNotEmpty)
            Text(
              [bizPhone, bizEmail].where((s) => s.isNotEmpty).join('  |  '),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          if (bizAddress.isNotEmpty)
            Text(
              bizAddress,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'INVOICE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 2,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Minimal Template Header
  Widget _buildMinimalHeader(
    BuildContext context,
    Color primaryColor,
    bool isDark,
    String bizName,
    String bizPhone,
    String bizEmail,
    String bizAddress,
    String bizGstin,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (settings.showLogo &&
                    settings.logoUrl.trim().isNotEmpty) ...[
                  Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Image.network(
                      settings.logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
                Text(
                  bizName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (bizPhone.isNotEmpty)
                  Text(
                    bizPhone,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                if (bizEmail.isNotEmpty)
                  Text(
                    bizEmail,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'INVOICE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 2,
                  color: primaryColor,
                ),
              ),
              Text(
                '${settings.invoicePrefix}0001',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Professional Template Header
  Widget _buildProfessionalHeader(
    BuildContext context,
    Color primaryColor,
    bool isDark,
    String bizName,
    String bizPhone,
    String bizEmail,
    String bizAddress,
    String bizGstin,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        border: Border(
          bottom: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          if (settings.showLogo && settings.logoUrl.trim().isNotEmpty) ...[
            Container(
              height: 48,
              width: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  settings.logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) {
                    AppLogger.error(err.toString());
                    AppLogger.error(stack.toString());
                    return Text(err.toString());
                  },
                ),
              ),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bizName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: primaryColor,
                  ),
                ),
                if (bizPhone.isNotEmpty || bizEmail.isNotEmpty)
                  Text(
                    [bizPhone, bizEmail].where((s) => s.isNotEmpty).join(' • '),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'INVOICE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
              Text(
                '${settings.invoicePrefix}0001',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Customer & Invoice Metadata Box
  Widget _buildCustomerMetaBox(
    BuildContext context,
    Color primaryColor,
    bool isDark,
    String bizGstin,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BILLED TO:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sampleCustomerName ?? 'Acme Enterprises Pvt Ltd',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '+91 98765 43210',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Invoice Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                'Due Date: ${DateTime.now().day + 7}/${DateTime.now().month}/${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              if (bizGstin.isNotEmpty)
                Text(
                  'GSTIN: $bizGstin',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Table Header
  Widget _buildItemsTableHeader(
    Color primaryColor,
    bool isDark,
    String template,
  ) {
    final bool isFilledHeader =
        template == 'modern' || template == 'professional';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isFilledHeader
            ? primaryColor
            : primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'ITEM',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isFilledHeader ? Colors.white : primaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'QTY',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isFilledHeader ? Colors.white : primaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'RATE',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isFilledHeader ? Colors.white : primaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TOTAL',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isFilledHeader ? Colors.white : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Single Item Row
  Widget _buildItemRow(
    String name,
    String qty,
    String rate,
    String total,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              rate,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              total,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Totals Summary Box
  Widget _buildTotalsBreakdown(
    Color primaryColor,
    bool isDark,
    double totalAmount,
    double taxAmount,
    double grandTotal,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                'Subtotal:',
                '₹${totalAmount.toStringAsFixed(2)}',
                isDark,
              ),
              if (settings.showTax)
                _buildSummaryRow(
                  'Tax (18% GST):',
                  '₹${taxAmount.toStringAsFixed(2)}',
                  isDark,
                ),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '₹${grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

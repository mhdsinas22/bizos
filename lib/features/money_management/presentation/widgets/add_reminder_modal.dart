import 'package:bizos/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AddReminderModal extends StatefulWidget {
  final String transactionId;
  final String personName;
  final String phone;
  final double balance;
  final String transactionType; // 'pay' or 'receive'
  final bool isPersonal;
  final Function(String notes) onSave;

  const AddReminderModal({
    super.key,
    required this.transactionId,
    required this.personName,
    required this.phone,
    required this.balance,
    required this.transactionType,
    required this.isPersonal,
    required this.onSave,
  });

  @override
  State<AddReminderModal> createState() => _AddReminderModalState();
}

class _AddReminderModalState extends State<AddReminderModal> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.text = 'Payment reminder sent for pending balance ₹${widget.balance.toStringAsFixed(2)}.';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsAppReminder() async {
    final cleanPhone = widget.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final typeText = widget.transactionType == 'receive'
        ? 'Hi ${widget.personName}, a friendly reminder regarding the pending amount of ₹${widget.balance.toStringAsFixed(2)}. Please arrange for payment at your earliest convenience. Thank you!'
        : 'Hi ${widget.personName}, regarding the payment of ₹${widget.balance.toStringAsFixed(2)}. Thank you!';

    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(typeText)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _submit() {
    final notes = _notesController.text.trim();
    widget.onSave(notes.isNotEmpty ? notes : 'Payment reminder logged');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Payment Reminder',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Recording a reminder logs an audit event without modifying the account balance.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reminder Notes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.phone.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: _sendWhatsAppReminder,
                icon: const Icon(Icons.chat, color: Colors.green),
                label: const Text('Send via WhatsApp first'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
            ],
            CustomButton(
              text: 'Log Reminder in Timeline',
              onPressed: _submit,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

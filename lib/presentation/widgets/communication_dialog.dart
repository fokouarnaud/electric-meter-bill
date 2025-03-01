import 'package:flutter/material.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/meter.dart';
import '../../services/email_service.dart';
import '../../services/sms_service.dart';

class CommunicationDialog extends StatefulWidget {
  final List<Bill> bills;
  final Meter meter;
  final bool isBulk;

  const CommunicationDialog({
    super.key,
    required this.bills,
    required this.meter,
    this.isBulk = false,
  });

  @override
  State<CommunicationDialog> createState() => _CommunicationDialogState();
}

class _CommunicationDialogState extends State<CommunicationDialog> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedMethod = 'email';

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.meter.contactEmail ?? '';
    _phoneController.text = widget.meter.contactPhone ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isBulk ? 'Send Multiple Bills' : 'Send Bill'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'email',
                  label: Text('Email'),
                  icon: Icon(Icons.email),
                ),
                ButtonSegment(
                  value: 'sms',
                  label: Text('SMS'),
                  icon: Icon(Icons.sms),
                ),
              ],
              selected: {_selectedMethod},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedMethod = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedMethod == 'email')
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
              )
            else
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            try {
              if (_selectedMethod == 'email') {
                if (widget.isBulk) {
                  await EmailService.sendBulkBillEmails(
                    bills: widget.bills,
                    meter: widget.meter,
                    recipientEmail: _emailController.text,
                  );
                } else {
                  await EmailService.sendBillEmail(
                    bill: widget.bills.first,
                    meter: widget.meter,
                    recipientEmail: _emailController.text,
                  );
                }
              } else {
                if (widget.isBulk) {
                  await SmsService.sendBulkBillSms(
                    bills: widget.bills,
                    meter: widget.meter,
                    phoneNumber: _phoneController.text,
                  );
                } else {
                  await SmsService.sendBillSms(
                    bill: widget.bills.first,
                    meter: widget.meter,
                    phoneNumber: _phoneController.text,
                  );
                }
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${_selectedMethod == 'email' ? 'Email' : 'SMS'} sent successfully',
                    ),
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}

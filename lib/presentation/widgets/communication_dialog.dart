import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/meter.dart';
import '../../services/email_service.dart';
import '../../services/sms_service.dart';
import '../../presentation/bloc/currency/currency_bloc.dart';

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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.isBulk ?
        (l10n?.sendAllBills ?? 'Send Multiple Bills') :
        (l10n?.sendBill ?? 'Send Bill')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            if (widget.isBulk)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '${l10n?.bills ?? "Bills"}: ${widget.bills.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'email',
                  label: Text(l10n?.email ?? 'Email'),
                  icon: const Icon(Icons.email),
                ),
                ButtonSegment(
                  value: 'sms',
                  label: Text(l10n?.sms ?? 'SMS'),
                  icon: const Icon(Icons.sms),
                ),
              ],
              selected: {_selectedMethod},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedMethod = selection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.communicationMethod ?? 'Communication Method',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_selectedMethod == 'email')
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n?.email ?? 'Email',
                  hintText: l10n?.contactEmail ?? 'Contact Email',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              )
            else
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: l10n?.phone ?? 'Phone Number',
                  hintText: l10n?.recipientPhone ?? 'Recipient Phone',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final recipient = _selectedMethod == 'email'
                ? _emailController.text.trim()
                : _phoneController.text.trim();
            
            if (recipient.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n?.requiredField ?? 'Required field'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Afficher un indicateur de chargement
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    Text(l10n?.sending ?? 'Sending...'),
                  ],
                ),
                duration: const Duration(seconds: 30),
              ),
            );

            try {
              if (_selectedMethod == 'email') {
                if (widget.isBulk) {
                  await EmailService.sendBulkBillEmails(
                    context: context,
                    bills: widget.bills,
                    meter: widget.meter,
                    recipientEmail: _emailController.text,
                  );
                } else {
                  await EmailService.sendBillEmail(
                    context: context,
                    bill: widget.bills.first,
                    meter: widget.meter,
                    recipientEmail: _emailController.text,
                  );
                }
              } else {
                 // Get the active currency from the BLoC
                final currencyBloc = BlocProvider.of<CurrencyBloc>(context);
                final currency = currencyBloc.state.activeCurrency;
                if (widget.isBulk) {
                  await SmsService.sendBulkBillSms(
                    context: context,
                    bills: widget.bills,
                    meter: widget.meter,
                    phoneNumber: _phoneController.text,
                    currency: currency,
                  );
                } else {
                  await SmsService.sendBillSms(
                    context: context,
                    bill: widget.bills.first,
                    meter: widget.meter,
                    phoneNumber: _phoneController.text,
                    currency: currency,
                  );
                }
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _selectedMethod == 'email' ?
                        (l10n?.emailSentSuccess ?? 'Email sent successfully') :
                        (l10n?.smsSentSuccess ?? 'SMS sent successfully'),
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

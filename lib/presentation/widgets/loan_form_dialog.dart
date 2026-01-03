import 'package:uuid/uuid.dart';
import 'package:audit2fund/domain/entities/loan_file.dart';
import 'package:audit2fund/presentation/providers/usecase_providers.dart';
import 'package:audit2fund/presentation/providers/loan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanFormDialog extends ConsumerStatefulWidget {
  final LoanFile? loan; // If null, create mode

  const LoanFormDialog({super.key, this.loan});

  @override
  ConsumerState<LoanFormDialog> createState() => _LoanFormDialogState();
}

class _LoanFormDialogState extends ConsumerState<LoanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _approvedController;
  late TextEditingController _requestedController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.loan?.clientName ?? '',
    );
    // Auto-generate ID if new, or us existing
    final initialId =
        widget.loan?.fileId ?? const Uuid().v4().substring(0, 8).toUpperCase();
    _idController = TextEditingController(text: initialId);

    _approvedController = TextEditingController(
      text: widget.loan?.approvedAmount.toString() ?? '',
    );
    _requestedController = TextEditingController(
      text: widget.loan?.requestedAmount?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.loan?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _approvedController.dispose();
    _requestedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.loan != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit File' : 'New Loan File'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name (Required)',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'File / Loan ID (Optional)',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _approvedController,
                        decoration: const InputDecoration(
                          labelText: 'Approved Amount',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _requestedController,
                        decoration: const InputDecoration(
                          labelText: 'Requested Amount (Opt)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save Changes' : 'Create File'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final useCases = ref.read(loanUseCasesProvider);

      try {
        if (widget.loan == null) {
          // Create
          await useCases.createLoan(
            clientName: _nameController.text,
            approvedAmount: double.parse(_approvedController.text),
            fileId: _idController.text.isEmpty ? null : _idController.text,
            requestedAmount: _requestedController.text.isEmpty
                ? null
                : double.parse(_requestedController.text),
            notes: _notesController.text,
          );
        } else {
          // Update
          await useCases.updateLoanDetails(
            loanId: widget.loan!.id,
            clientName: _nameController.text,
            approvedAmount: double.parse(_approvedController.text),
            fileId: _idController.text.isEmpty ? null : _idController.text,
            requestedAmount: _requestedController.text.isEmpty
                ? null
                : double.parse(_requestedController.text),
            notes: _notesController.text,
          );
        }

        // Invalidate provider to refresh list
        ref.invalidate(allLoansProvider);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

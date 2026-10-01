import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FailedReasonSheet extends StatefulWidget {
  final Function(String reason) onSubmit;

  const FailedReasonSheet({
    super.key,
    required this.onSubmit,
  });

  static Future<void> show(BuildContext context, Function(String reason) onSubmit) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FailedReasonSheet(onSubmit: onSubmit),
    );
  }

  @override
  State<FailedReasonSheet> createState() => _FailedReasonSheetState();
}

class _FailedReasonSheetState extends State<FailedReasonSheet> {
  final TextEditingController _reasonController = TextEditingController();
  String? _errorText;

  final List<String> _quickReasons = [
    'Store / Mall Closed',
    'Customer Not Available',
    'Address Not Found',
    'Entry Denied by Security',
    'Refused to Accept Delivery',
    'Payment / Invoice Discrepancy',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _reasonController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText = 'Please enter or select a reason for failed delivery';
      });
      return;
    }
    Navigator.of(context).pop();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBarPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        minimum: EdgeInsets.only(
          bottom: bottomInset > 0 ? bottomInset + 12 : (navBarPadding > 0 ? navBarPadding + 8 : 16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with alert icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusFailedBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.statusFailedBorder),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.statusFailedText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark Delivery as Failed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Specify the reason for unable to deliver',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 16),

            // Quick reasons
            const Text(
              'Quick Select:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons.map((reason) {
                final isSelected = _reasonController.text == reason;
                return ChoiceChip(
                  label: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.brandRed,
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                    color: isSelected ? AppColors.brandRed : AppColors.divider,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _reasonController.text = selected ? reason : '';
                      _errorText = null;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Text input
            const Text(
              'Reason for Failed Delivery',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                errorText: _errorText,
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'SUBMIT FAILED STATUS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}
}

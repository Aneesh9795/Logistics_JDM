import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class DeliveryHelper {
  DeliveryHelper._();

  static Future<void> startDeliveryFlow({
    required BuildContext context,
    String? docketNo,
    required Function(String imagePath) onConfirmed,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SmartDeliveryVerificationSheet(
        docketNo: docketNo,
        onConfirmed: onConfirmed,
      ),
    );
  }
}

class _SmartDeliveryVerificationSheet extends StatefulWidget {
  final String? docketNo;
  final Function(String imagePath) onConfirmed;

  const _SmartDeliveryVerificationSheet({
    this.docketNo,
    required this.onConfirmed,
  });

  @override
  State<_SmartDeliveryVerificationSheet> createState() => _SmartDeliveryVerificationSheetState();
}

class _SmartDeliveryVerificationSheetState extends State<_SmartDeliveryVerificationSheet> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isProcessing = true);
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (photo != null && mounted) {
        setState(() {
          _capturedImage = photo;
          _isProcessing = false;
        });
      } else if (mounted) {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access camera/gallery: $e'),
            backgroundColor: AppColors.brandRed,
          ),
        );
      }
    }
  }

  void _completeDelivery() {
    if (_capturedImage == null) return;
    Navigator.of(context).pop();
    widget.onConfirmed(_capturedImage!.path);
  }

  @override
  Widget build(BuildContext context) {
    final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 34),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.statusDeliveredBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.statusDeliveredBorder),
                          ),
                          child: const Icon(
                            Icons.verified_outlined,
                            color: AppColors.statusDeliveredText,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Proof of Delivery (POD)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryNavy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.docketNo != null
                                    ? 'Docket: ${widget.docketNo} • Capture photo'
                                    : 'Capture invoice or signed challan',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 14),

              // Capture Viewfinder / Preview Card
              if (_capturedImage == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.divider,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 32,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Capture Invoice or Package Photo',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Signed invoice copy or photo at doorstep is mandatory',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      if (_isProcessing)
                        const CircularProgressIndicator(color: AppColors.primaryNavy)
                      else
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.photo_camera, color: Colors.white, size: 18),
                                label: const Text('OPEN CAMERA'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryNavy,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined, size: 18),
                                label: const Text('GALLERY'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ] else ...[
                // Captured Photo Preview with Geotag Badge & Retake
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 220,
                        color: Colors.black,
                        child: kIsWeb
                            ? Image.network(_capturedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                      ),

                      // Top Retake button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: InkWell(
                          onTap: () => _pickImage(ImageSource.camera),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white38),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.replay_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'RETAKE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bottom Geotag Watermark
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(200),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Verified Proof of Delivery (POD)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Timestamp: $nowFormatted',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Complete Delivery Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _capturedImage != null ? _completeDelivery : null,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  label: const Text(
                    'CONFIRM & DELIVER ORDER',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusDeliveredText,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _capturedImage != null ? 2 : 0,
                  ),
                ),
              ),
              if (_capturedImage == null) ...[
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    '⚠️ Photo proof is required to enable confirmation',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

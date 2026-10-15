import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swasth_id_app/services/ocr_aadhaar_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AadhaarScanSheet
//
// Usage:
//   final result = await AadhaarScanSheet.show(context);
//   if (result != null) { /* auto-fill form */ }
// ─────────────────────────────────────────────────────────────────────────────

class AadhaarScanSheet extends StatefulWidget {
  const AadhaarScanSheet({super.key});

  /// Convenience method — shows the bottom sheet and returns an [AadhaarOcrResult]
  /// when the user taps "Use These Details", or null if dismissed.
  static Future<AadhaarOcrResult?> show(BuildContext context) {
    return showModalBottomSheet<AadhaarOcrResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AadhaarScanSheet(),
    );
  }

  @override
  State<AadhaarScanSheet> createState() => _AadhaarScanSheetState();
}

enum _ScanState { idle, scanning, success, failed }

class _AadhaarScanSheetState extends State<AadhaarScanSheet>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  _ScanState _state = _ScanState.idle;
  AadhaarOcrResult? _result;
  Uint8List? _previewBytes;

  // Editable controllers
  final _aadhaarCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();

  static const _purple = Color(0xFF7C3AED);
  static const _purpleSoft = Color(0xFFF3EEFF);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _aadhaarCtrl.dispose();
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  // ── Pick & scan ─────────────────────────────────────────────────────────

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _previewBytes = bytes;
      _state = _ScanState.scanning;
      _result = null;
    });

    final result = await OcrAadhaarService.scanAadhaar(
      imageBytes: bytes,
      filename: picked.name,
    );

    if (!mounted) return;

    setState(() {
      _result = result;
      _state = (result.success && result.hasData)
          ? _ScanState.success
          : _ScanState.failed;

      if (_state == _ScanState.success) {
        _aadhaarCtrl.text = result.aadhaarNumber ?? '';
        _nameCtrl.text = result.name ?? '';
        _dobCtrl.text = result.dob ?? '';
        _genderCtrl.text = result.gender ?? '';
      }
    });
  }

  // ── Confidence UI ────────────────────────────────────────────────────────

  ({Color bg, Color fg, String label, IconData icon}) _confidenceMeta(
      OcrConfidence c) {
    switch (c) {
      case OcrConfidence.high:
        return (
          bg: const Color(0xFFDCFCE7),
          fg: const Color(0xFF16A34A),
          label: 'High confidence',
          icon: Icons.verified_rounded
        );
      case OcrConfidence.medium:
        return (
          bg: const Color(0xFFFFFBEB),
          fg: const Color(0xFFD97706),
          label: 'Medium confidence — please verify',
          icon: Icons.warning_amber_rounded
        );
      case OcrConfidence.low:
        return (
          bg: const Color(0xFFFEF2F2),
          fg: const Color(0xFFDC2626),
          label: 'Low confidence — manual entry recommended',
          icon: Icons.error_outline_rounded
        );
      case OcrConfidence.none:
        return (
          bg: Colors.grey.shade100,
          fg: Colors.grey,
          label: 'No data extracted',
          icon: Icons.info_outline
        );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _purpleSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.document_scanner_rounded,
                        color: _purple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scan Aadhaar Card',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('Camera or gallery · Auto-fills your details',
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── State Machine ──────────────────────────────────────────
              if (_state == _ScanState.idle) _buildIdleState(),
              if (_state == _ScanState.scanning) _buildScanningState(),
              if (_state == _ScanState.success) _buildSuccessState(),
              if (_state == _ScanState.failed) _buildFailedState(),
            ],
          ),
        ),
      ),
    );
  }

  // ── IDLE STATE ──────────────────────────────────────────────────────────

  Widget _buildIdleState() {
    return Column(
      children: [
        // Preview placeholder
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _purpleSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _purple.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card_rounded,
                  size: 48, color: _purple.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text('Position your Aadhaar card clearly',
                  style: TextStyle(
                      color: _purple.withOpacity(0.7), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Source buttons
        Row(
          children: [
            Expanded(
              child: _SourceButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: _purple,
                onTap: () => _pick(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: const Color(0xFF0284C7),
                onTap: () => _pick(ImageSource.gallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _HintRow(
            icon: Icons.tips_and_updates_outlined,
            text:
                'Tip: Ensure good lighting. Keep all 4 corners of the card visible.'),
      ],
    );
  }

  // ── SCANNING STATE ──────────────────────────────────────────────────────

  Widget _buildScanningState() {
    return Column(
      children: [
        // Image preview with pulse overlay
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_previewBytes != null)
                Image.memory(_previewBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover),
              Container(
                height: 180,
                color: Colors.black.withOpacity(0.45),
              ),
              ScaleTransition(
                scale: _pulseAnim,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Reading Aadhaar…',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Extracting name, DOB & number',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SUCCESS STATE ───────────────────────────────────────────────────────

  Widget _buildSuccessState() {
    final meta = _confidenceMeta(_result!.confidence);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Details extracted successfully',
                    style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              // Confidence badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: meta.bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: meta.fg.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(meta.icon, size: 11, color: meta.fg),
                    const SizedBox(width: 4),
                    Text(meta.label,
                        style: TextStyle(
                            fontSize: 10,
                            color: meta.fg,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Editable fields
        const Text('Review & Edit Extracted Details',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
                letterSpacing: 0.4)),
        const SizedBox(height: 12),

        _OcrField(
          controller: _aadhaarCtrl,
          label: 'Aadhaar Number',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          maxLength: 12,
          isHighlighted: _result!.aadhaarNumber != null,
        ),
        const SizedBox(height: 12),
        _OcrField(
          controller: _nameCtrl,
          label: 'Full Name',
          icon: Icons.person_outline_rounded,
          isHighlighted: _result!.name != null,
        ),
        const SizedBox(height: 12),
        _OcrField(
          controller: _dobCtrl,
          label: 'Date of Birth (DD/MM/YYYY)',
          icon: Icons.cake_outlined,
          isHighlighted: _result!.dob != null,
        ),
        const SizedBox(height: 12),
        _OcrField(
          controller: _genderCtrl,
          label: 'Gender',
          icon: Icons.wc_outlined,
          isHighlighted: _result!.gender != null,
        ),
        const SizedBox(height: 20),

        // Action buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Return updated result with edited values
              Navigator.pop(
                context,
                AadhaarOcrResult(
                  success: true,
                  aadhaarNumber: _aadhaarCtrl.text.trim().isEmpty
                      ? null
                      : _aadhaarCtrl.text.trim(),
                  name: _nameCtrl.text.trim().isEmpty
                      ? null
                      : _nameCtrl.text.trim(),
                  dob: _dobCtrl.text.trim().isEmpty
                      ? null
                      : _dobCtrl.text.trim(),
                  gender: _genderCtrl.text.trim().isEmpty
                      ? null
                      : _genderCtrl.text.trim(),
                  confidence: _result!.confidence,
                ),
              );
            },
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: const Text('Use These Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => setState(() {
              _state = _ScanState.idle;
              _result = null;
              _previewBytes = null;
            }),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Scan Again'),
            style: TextButton.styleFrom(foregroundColor: _purple),
          ),
        ),
      ],
    );
  }

  // ── FAILED STATE ────────────────────────────────────────────────────────

  Widget _buildFailedState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.document_scanner_outlined,
                  size: 40, color: Color(0xFFDC2626)),
              const SizedBox(height: 10),
              const Text('Unable to extract details',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFFDC2626))),
              const SizedBox(height: 6),
              Text(
                _result?.errorMessage ??
                    'OCR could not read the card. Try with better lighting or a clearer image.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _SourceButton(
                icon: Icons.camera_alt_rounded,
                label: 'Try Camera',
                color: _purple,
                onTap: () => _pick(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceButton(
                icon: Icons.photo_library_rounded,
                label: 'Try Gallery',
                color: const Color(0xFF0284C7),
                onTap: () => _pick(ImageSource.gallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _HintRow(
            icon: Icons.light_mode_outlined,
            text:
                'Use good lighting. Avoid glare. Keep card flat and in focus.'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _OcrField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isHighlighted;
  final TextInputType keyboardType;
  final int? maxLength;

  const _OcrField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isHighlighted = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isHighlighted ? purple : Colors.grey,
          size: 20,
        ),
        counterText: '',
        filled: true,
        fillColor: isHighlighted
            ? const Color(0xFFF3EEFF)
            : Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isHighlighted
                ? purple.withOpacity(0.4)
                : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: purple, width: 1.8),
        ),
        labelStyle: TextStyle(
          color: isHighlighted ? purple : Colors.grey,
          fontSize: 13,
        ),
        suffixIcon: isHighlighted
            ? const Icon(Icons.auto_fix_high_rounded,
                size: 16, color: Color(0xFF7C3AED))
            : null,
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HintRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      ],
    );
  }
}

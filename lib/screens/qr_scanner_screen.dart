import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/totp_service.dart';
import '../utils/constants.dart';

class QRScannerScreen extends StatefulWidget {
  final TOTPService totpService;

  const QRScannerScreen({
    super.key,
    required this.totpService,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      final account = widget.totpService.parseOtpAuthUri(code);

      if (account != null && mounted) {
        Navigator.pop(context, account);
      } else {
        _showError('Geçersiz QR kod');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showError('QR kod okunamadı: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Tara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding,
                  vertical: AppConstants.defaultPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: const Text(
                  'QR kodu çerçeveye hizalayın',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

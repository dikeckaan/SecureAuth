import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

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
  bool _torchOn = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    final account = widget.totpService.parseOtpAuthUri(code);

    if (account != null && mounted) {
      Navigator.pop(context, account);
    } else {
      final l10n = AppLocalizations.of(context)!;
      _showError(l10n.invalidQRCode);
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.scanQRCode),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? AppColors.warning : Colors.white,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            size: Size.infinite,
          ),
          // Scan frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  // Corner accents
                  ..._buildCorners(),
                ],
              ),
            ),
          ),
          // Bottom instruction
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLG,
                  vertical: AppConstants.paddingMD,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.alignQRCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 4.0;
    final color = Theme.of(context).colorScheme.primary;

    return [
      // Top left
      Positioned(
        top: 0,
        left: 0,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
                corner: _Corner.topLeft,
                color: color,
                thickness: thickness),
          ),
        ),
      ),
      // Top right
      Positioned(
        top: 0,
        right: 0,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
                corner: _Corner.topRight,
                color: color,
                thickness: thickness),
          ),
        ),
      ),
      // Bottom left
      Positioned(
        bottom: 0,
        left: 0,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
                corner: _Corner.bottomLeft,
                color: color,
                thickness: thickness),
          ),
        ),
      ),
      // Bottom right
      Positioned(
        bottom: 0,
        right: 0,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
                corner: _Corner.bottomRight,
                color: color,
                thickness: thickness),
          ),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(128);
    final center = size.center(Offset.zero);
    const scanSize = 260.0;
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanSize,
      height: scanSize,
    );
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(fullRect),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
            scanRect,
            const Radius.circular(AppConstants.radiusLG),
          )),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerPainter extends CustomPainter {
  final _Corner corner;
  final Color color;
  final double thickness;

  _CornerPainter({
    required this.corner,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
      case _Corner.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
      case _Corner.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
      case _Corner.bottomRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

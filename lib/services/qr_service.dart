import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class QRService {
  Future<Uint8List> generateQRImage(String data, {int size = 512}) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('QR kod oluşturulamadı');
    }

    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
      embeddedImageStyle: null,
      embeddedImage: null,
    );

    final picturRecorder = ui.PictureRecorder();
    final canvas = Canvas(picturRecorder);

    painter.paint(canvas, Size(size.toDouble(), size.toDouble()));

    final picture = picturRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Widget buildQRWidget(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: true,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_payment.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.isNotEmpty) {
        _isProcessing = true;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentProcessScreen(
              amount: 10.00,
              merchant: 'ShopABC · KHQR',
              currency: FinanceCurrency.usd,
            ),
          ),
        );

        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Flash',
            onPressed: () {
              _scannerController.toggleTorch();
            },
            icon: const Icon(Icons.flash_on_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // Dark overlay around scanner area
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Corner decorations
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _corner()),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Transform.rotate(angle: 1.5708, child: _corner()),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Transform.rotate(angle: 3.14159, child: _corner()),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Transform.rotate(angle: -1.5708, child: _corner()),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 90,
            child: Column(
              children: [
                const Text(
                  'Scan QR Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Place the QR code inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner() {
    return Container(
      width: 35,
      height: 35,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white, width: 5),
          left: BorderSide(color: Colors.white, width: 5),
        ),
      ),
    );
  }
}

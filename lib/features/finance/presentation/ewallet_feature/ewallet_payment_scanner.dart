import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
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
            builder: (_) => Payment(
              amount: 0.0,
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
      backgroundColor: AppColors.darkBgPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // QR CAMERA
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // DARK OVERLAY
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.25, 0.65, 1.0],
                  colors: [
                    AppColors.darkBgPrimary.withValues(alpha: 0.72),
                    AppColors.darkBgPrimary.withValues(alpha: 0.10),
                    AppColors.darkBgPrimary.withValues(alpha: 0.04),
                    AppColors.darkBgPrimary.withValues(alpha: 0.86),
                  ],
                ),
              ),
            ),
          ),

          // HEADER
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceGlass,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.darkBorderSubtle),
                ),
                child: Row(
                  children: [
                    // QR LOGO
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.darkPrimarySoft,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.darkBorderSubtle),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: AppColors.darkTextPrimary,
                        size: 29,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // TITLE
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GenLink',
                            style: TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan & Pay',
                            style: TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // CLOSE BUTTON
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.darkPrimarySoft,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.darkBorderSubtle,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.darkTextPrimary,
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SCANNER FRAME
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.darkTextPrimary.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // SCANNER CORNERS
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

          // SCANNER INSTRUCTION
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
                    color: AppColors.darkTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Place the QR code inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM CANCEL BUTTON
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
                  foregroundColor: AppColors.darkTextPrimary,
                  backgroundColor: AppColors.darkSurfaceGlass,
                  side: const BorderSide(color: AppColors.darkBorderStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SCANNER CORNER
  Widget _corner() {
    return Container(
      width: 35,
      height: 35,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.darkTextPrimary, width: 5),
          left: BorderSide(color: AppColors.darkTextPrimary, width: 5),
        ),
      ),
    );
  }
}

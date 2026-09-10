import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/achievements/controllers/scan_handler.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Camera QR scanner for the Jugendplatz badges. Reads a
/// `https://<host>/scan/<slug>` code, records the scan and celebrates any
/// newly unlocked tier.
@RoutePage()
class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  // Pinch-to-zoom state. Zoom scale is 0.0–1.0 (mobile_scanner API).
  double _zoom = 0.0;
  double _baseZoom = 0.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    final slug = scanSlugFromRaw(raw);
    if (slug == null) return; // not one of our codes — keep scanning

    _handled = true;
    await _controller.stop();
    if (!mounted) return;

    final ok = await processScan(context, ref, slug);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).maybePop();
    } else {
      // Let the user try again instead of leaving the screen.
      _handled = false;
      await _controller.start();
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoom = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // details.scale: 1.0 = unchanged, >1 pinch-out (zoom in), <1 pinch-in.
    final newZoom = (_baseZoom + (details.scale - 1.0)).clamp(0.0, 1.0);
    if ((newZoom - _zoom).abs() < 0.01) return;
    _zoom = newZoom;
    _controller.setZoomScale(newZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SubPageAppBar(titleText: 'Scannen'),
      body: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        child: MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Kamera nicht verfügbar. Bitte erlaube den Kamerazugriff in den Einstellungen.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

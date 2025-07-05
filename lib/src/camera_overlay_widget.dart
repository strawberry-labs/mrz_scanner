import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:mrz_scanner/src/mrz_navigator.dart';

class CameraOverlayWidget extends StatefulWidget {
  final Function(PhotoCameraState photoCameraState) onPhotoCameraState;
  final PhotoCameraState photoCameraState;
  final ScanMode scanMode;
  
  const CameraOverlayWidget({
    super.key,
    required this.onPhotoCameraState,
    required this.photoCameraState,
    required this.scanMode,
  });

  @override
  State<CameraOverlayWidget> createState() => _CameraOverlayWidgetState();
}

class _CameraOverlayWidgetState extends State<CameraOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;
  @override
  void initState() {
    super.initState();
    widget.onPhotoCameraState(widget.photoCameraState);
    initializeProvider(this);
  }

  @override
  void dispose() {
    animation.removeListener(changeAnimationListener);
    animationController.dispose();
    super.dispose();
  }

  initializeProvider(TickerProvider provider) {
    animationController = AnimationController(
        vsync: provider,
        duration: const Duration(milliseconds: 750),
        reverseDuration: const Duration(
          milliseconds: 250,
        ));
    animation = Tween<double>(begin: 0, end: 1).animate(animationController)
      ..addListener(changeAnimationListener);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isPortrait = screenSize.height > screenSize.width;
    final sideText = widget.scanMode == ScanMode.front ? 'FRONT SIDE' : 'BACK SIDE';
    
    return Stack(
      children: [
        SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: CustomPaint(
            painter: HorizontalDocumentPainter(isPortrait: isPortrait),
          ),
        ),
        IgnorePointer(
          child: ClipPath(
            clipper: HorizontalDocumentClipper(isPortrait: isPortrait),
            child: Opacity(
              opacity: 1 - (animation.value),
              child: Container(
                color: const Color(0x8E0D0C0A),
              ),
            ),
          ),
        ),
        // Instructional text overlay
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 100,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Scan your Emirates ID',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sideText,
                    style: TextStyle(
                      color: widget.scanMode == ScanMode.front ? Colors.blue[300] : Colors.green[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void changeAnimationListener() => setState(() {});
}

// Helper function to calculate rectangle dimensions with 5.5:8.5 aspect ratio
Rect calculateDocumentRect(double screenWidth, double screenHeight, bool isPortrait) {
  // 5.5:8.5 aspect ratio for landscape rectangle (height:width)
  const aspectRatio = 5.5 / 8.5; // height / width for landscape rectangle
  
  double rectWidth, rectHeight;
  
  if (isPortrait) {
    // In portrait mode: fit the rectangle within screen bounds
    rectWidth = screenWidth * 0.85;
    rectHeight = rectWidth * aspectRatio;
    
    // If calculated height is too tall, adjust based on height
    if (rectHeight > screenHeight * 0.4) {
      rectHeight = screenHeight * 0.4;
      rectWidth = rectHeight / aspectRatio;
    }
  } else {
    // In landscape mode: maintain the aspect ratio
    rectWidth = screenWidth * 0.75;
    rectHeight = rectWidth * aspectRatio;
    
    // If calculated height is too tall, adjust based on height
    if (rectHeight > screenHeight * 0.6) {
      rectHeight = screenHeight * 0.6;
      rectWidth = rectHeight / aspectRatio;
    }
  }
  
  return Rect.fromCenter(
    center: Offset(screenWidth / 2, screenHeight / 2),
    width: rectWidth,
    height: rectHeight,
  );
}

class HorizontalDocumentClipper extends CustomClipper<Path> {
  final bool isPortrait;
  
  HorizontalDocumentClipper({required this.isPortrait});

  @override
  Path getClip(Size size) {
    final background = Rect.fromLTWH(0.0, 0.0, size.width, size.height);

    final width = size.width;
    final height = size.height;
    const radius = 15.0;

    // Create a horizontal rectangle with 5.5:8.5 aspect ratio
    final documentRect = calculateDocumentRect(width, height, isPortrait);

    final documentArea = RRect.fromRectAndRadius(
      documentRect,
      const Radius.circular(radius),
    );

    return Path()
      ..addRect(background)
      ..addRRect(documentArea)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class HorizontalDocumentPainter extends CustomPainter {
  final bool isPortrait;
  
  HorizontalDocumentPainter({required this.isPortrait});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final width = size.width;
    final height = size.height;
    const radius = 15.0;

    Path path = Path();

    // Create a horizontal rectangle with 5.5:8.5 aspect ratio
    final documentRect = calculateDocumentRect(width, height, isPortrait);

    final documentArea = RRect.fromRectAndRadius(
      documentRect,
      const Radius.circular(radius),
    );

    path.addRRect(documentArea);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

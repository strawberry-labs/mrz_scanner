import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class CameraOverlayWidget extends StatefulWidget {
  final Function(PhotoCameraState photoCameraState) onPhotoCameraState;
  final PhotoCameraState photoCameraState;
  const CameraOverlayWidget(
      {super.key,
      required this.onPhotoCameraState,
      required this.photoCameraState});

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
  Widget build(BuildContext context) => Stack(
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            child: CustomPaint(
              painter: VerticalDocumentPainter(),
            ),
          ),
          IgnorePointer(
            child: ClipPath(
              clipper: VerticalDocumentClipper(),
              child: Opacity(
                opacity: 1 - (animation.value),
                child: Container(
                  color: const Color(0x8E0D0C0A),
                ),
              ),
            ),
          )
        ],
      );

  void changeAnimationListener() => setState(() {});
}

class VerticalDocumentClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final background = Rect.fromLTWH(0.0, 0.0, size.width, size.height);

    final width = size.width;
    final height = size.height;
    const radius = 15.0;

    final documentRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: width * 0.75,
      height: height * 0.6,
    );

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

class VerticalDocumentPainter extends CustomPainter {
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

    final documentRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: width * 0.75,
      height: height * 0.6,
    );

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

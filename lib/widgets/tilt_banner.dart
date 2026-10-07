import 'package:flutter/material.dart';

class TiltBanner extends StatefulWidget {
  final Widget? child;
  final Widget? background;
  final Widget? foreground;
  final double bgMultiplier;
  final double fgMultiplier;
  final VoidCallback? onTap;
  final bool enableTilt;

  const TiltBanner({
    super.key,
    this.child,
    this.background,
    this.foreground,
    this.bgMultiplier = 0.4,
    this.fgMultiplier = 1.0,
    this.onTap,
    this.enableTilt = true,
  });

  @override
  State<TiltBanner> createState() => _TiltBannerState();
}

class _TiltBannerState extends State<TiltBanner> with SingleTickerProviderStateMixin {
  final GlobalKey _widgetKey = GlobalKey();
  
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  late AnimationController _animController;
  late Animation<double> _animationX;
  late Animation<double> _animationY;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animController.addListener(() {
      setState(() {
        _tiltX = _animationX.value;
        _tiltY = _animationY.value;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    _animController.stop();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox? renderBox = _widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final localPos = renderBox.globalToLocal(details.globalPosition);

    // Calculate normalized coordinates (-1.0 to 1.0) relative to the center
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    final double offsetX = (localPos.dx - centerX) / centerX;
    final double offsetY = (localPos.dy - centerY) / centerY;

    // Horizontal drag (X offset) rotates around Y-axis (tiltY).
    // Vertical drag (Y offset) rotates around X-axis (tiltX, inverted).
    // Clamped to ±0.06 radians for a highly subtle, elegant perspective effect.
    setState(() {
      _tiltY = (offsetX * 0.06).clamp(-0.06, 0.06);
      _tiltX = (-offsetY * 0.06).clamp(-0.06, 0.06);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _animationX = Tween<double>(begin: _tiltX, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animationY = Tween<double>(begin: _tiltY, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableTilt) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (widget.background != null) widget.background!,
            if (widget.child != null) widget.child!,
            if (widget.foreground != null) widget.foreground!,
          ],
        ),
      );
    }

    final Widget cardBody = Stack(
      key: _widgetKey,
      fit: StackFit.passthrough,
      children: [
        if (widget.background != null)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(_tiltX * widget.bgMultiplier)
              ..rotateY(_tiltY * widget.bgMultiplier),
            child: widget.background,
          ),
        if (widget.child != null)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_tiltX)
              ..rotateY(_tiltY),
            child: widget.child,
          ),
        if (widget.foreground != null)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_tiltX * widget.fgMultiplier)
              ..rotateY(_tiltY * widget.fgMultiplier),
            child: widget.foreground,
          ),
      ],
    );

    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: cardBody,
    );
  }
}

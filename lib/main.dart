import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PivotButton(
          maxTilt: math.pi / 6,
          height: 100,
          width: 300,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.amber)),
            child: ListTile(
              leading: Icon(Icons.alarm),
              title: Text('Transform button'),
            ),
          ),
        ),
      ),
    );
  }
}

class PivotButton extends StatefulWidget {
  final double maxTilt;
  final double height;
  final double width;
  final double perspectiveScale;
  final Widget child;
  const PivotButton({
    this.maxTilt = math.pi / 6,
    @required this.height,
    @required this.width,
    this.perspectiveScale = 0.003,
    this.child,
  });
  @override
  _PivotButtonState createState() => _PivotButtonState();
}

class _PivotButtonState extends State<PivotButton>
    with TickerProviderStateMixin {
  double tiltAngleX;
  double tiltAngleY;
  double scaleSize;
  Animation _xTiltAnimation;
  Animation _yTiltAnimation;
  Animation _scaleAnimation;
  AnimationController _tiltXAnimationController;
  AnimationController _tiltYAnimationController;
  AnimationController _scaleAnimationController;
  @override
  void initState() {
    super.initState();
    tiltAngleX = 0.0;
    tiltAngleY = 0.0;
    scaleSize = 1.0;
    _tiltXAnimationController = _haveController(Duration(milliseconds: 100));
    _tiltYAnimationController = _haveController(Duration(milliseconds: 100));
    _scaleAnimationController = _haveController(Duration(milliseconds: 70));
    _scaleAnimation =
        Tween<double>(begin: scaleSize).animate(_scaleAnimationController);
    _xTiltAnimation =
        Tween<double>(begin: tiltAngleX).animate(_tiltXAnimationController);
    _yTiltAnimation =
        Tween<double>(begin: tiltAngleY).animate(_tiltYAnimationController);
    _scaleAnimationController.addListener(() {
      setState(() {
        scaleSize = _scaleAnimation.value;
      });
    });
    _tiltXAnimationController.addListener(() {
      setState(() {
        tiltAngleX = _xTiltAnimation.value;
      });
    });
    _tiltYAnimationController.addListener(() {
      setState(() {
        tiltAngleY = _yTiltAnimation.value;
      });
    });
  }

  AnimationController _haveController(Duration duration) =>
      AnimationController(vsync: this, duration: duration);
  @override
  void dispose() {
    super.dispose();
    _tiltXAnimationController.dispose();
    _tiltYAnimationController.dispose();
    _scaleAnimationController.dispose();
  }

  void _handleTapRelease() {
    _scaleAnimationController.reverse(from: scaleSize);
    _tiltXAnimationController.reverse(from: tiltAngleX);
    _tiltYAnimationController.reverse(from: tiltAngleY);
    tiltAngleX = 0.0;
    tiltAngleY = 0.0;
    scaleSize = 1.0;
  }

  void _handleTapDown(TapDownDetails details) {
    // get touch point location with respect to button
    double touchPointX = details.localPosition.dx;
    double touchPointY = details.localPosition.dy;
    // calculate touch point distance from center
    double touchPointDistanceFromCenter = (Offset(touchPointX, touchPointY) -
            Offset(widget.width / 2, widget.height / 2))
        .distance;
    // calculate tilt angle: the further the touch point is from the center, the greater the tilt
    // taking into account unequal height and width of the button
    double tiltAngle = widget.maxTilt *
        touchPointDistanceFromCenter *
        math.sqrt2 /
        math.max(widget.width, widget.height);
    // calculate distance of touch point from edge of both x and y axis
    double distFromEdgeY = touchPointY < widget.height / 2
        ? touchPointY
        : widget.height - touchPointY;
    double distFromEdgeX = touchPointX < widget.width / 2
        ? touchPointX
        : widget.width - touchPointX;
    // calculate tilt angle in x and y axis
    tiltAngleX = tiltAngle *
        (distFromEdgeX / (distFromEdgeX + distFromEdgeY)) *
        (touchPointY > widget.height / 2 ? 1 : -1);
    tiltAngleY = tiltAngle *
        (distFromEdgeY / (distFromEdgeX + distFromEdgeY)) *
        (touchPointX < widget.width / 2 ? 1 : -1);
    _xTiltAnimation = Tween<double>(begin: 0.0, end: tiltAngleX)
        .animate(_tiltXAnimationController);
    _yTiltAnimation = Tween<double>(begin: 0.0, end: tiltAngleY)
        .animate(_tiltYAnimationController);
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(_scaleAnimationController);
    _scaleAnimationController.forward();
    _tiltXAnimationController.forward();
    _tiltYAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _handleTapDown(details),
      onTapUp: (_) => _handleTapRelease(),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, widget.perspectiveScale)
          ..rotateX(tiltAngleX)
          ..rotateY(tiltAngleY)
          ..scale(scaleSize),
        alignment: FractionalOffset.center,
        child: Container(
          alignment: Alignment.center,
          child: widget.child,
          height: widget.height,
          width: widget.width,
        ),
      ),
    );
  }
}

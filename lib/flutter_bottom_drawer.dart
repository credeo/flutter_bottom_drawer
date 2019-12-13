library flutter_bottom_drawer;

import 'package:flutter/material.dart';

class BottomDrawer extends StatefulWidget {
  /// Optional widget which does not scroll with the rest of the drawer.
  final Widget header;

  /// Scrollable elements
  final List<Widget> children;

  /// Values needs to be between 0.0 - 1.0. They match percentage of available drawer height
  /// [stops] length needs to be >= 2
  /// Needs to be entered in ascending order
  /// If used with [snap] then the drawer will automatically move to nearest stop after user dragging ends
  final List<double> stops;

  /// Drawer initial height
  /// Used as index in [stops]
  final int initialStopIndex;

  /// Drawer container border radius
  final BorderRadius borderRadius;

  /// Whether drawer should automatically adjust its size when user dragging ends
  /// It will move to the nearest stop in [stops]
  final bool snap;

  /// Duration of animation when [snap] triggers
  final Duration snapAnimationDuration;

  /// Whether drawer should rebuild its constraints on each build or only first time
  /// Useful if final drawer height is not available on the first drawer build
  final bool rebuildConstraints;

  /// Padding for drawer list
  final EdgeInsets listViewPadding;

  /// Drawer container shadow
  final BoxShadow shadow;

  const BottomDrawer({
    this.children = const [],
    this.listViewPadding = EdgeInsets.zero,
    this.snapAnimationDuration = const Duration(milliseconds: 256),
    this.stops = const [0.2, 1.0],
    this.borderRadius,
    this.header,
    this.initialStopIndex = 0,
    this.rebuildConstraints = false,
    this.snap = true,
    this.shadow,
  })  : assert(initialStopIndex < stops.length, 'initialStopIndex cannot be greater than stops.length'),
        assert(stops.length >= 2, 'minimum number of stops is 2');

  @override
  State<StatefulWidget> createState() => BottomDrawerState();
}

class BottomDrawerState extends State<BottomDrawer> {
  ScrollController _scrollController = ScrollController();
  final GlobalKey _containerKey = GlobalKey();

  double currentHeight;
  double maxDrawerHeight;
  double minDrawerHeight;
  double height;
  bool dragging = false;
  bool firstTime = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (firstTime) {
        height = constraints.maxHeight;
        maxDrawerHeight = widget.stops.last * height;
        minDrawerHeight = widget.stops.first * height;
        currentHeight = height * widget.stops[widget.initialStopIndex];
        firstTime = false;
      } else if (widget.rebuildConstraints) {
        height = constraints.maxHeight;
        maxDrawerHeight = widget.stops.last * height;
        minDrawerHeight = widget.stops.first * height;
      }

      return Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          key: _containerKey,
          duration: (dragging || !widget.snap) ? Duration.zero : widget.snapAnimationDuration,
          width: double.infinity,
          height: currentHeight,
          child: SizedBox(
            height: currentHeight,
            width: double.infinity,
            child: GestureDetector(
              onVerticalDragStart: (details) {
                dragging = true;
                final box = _containerKey.currentContext.findRenderObject() as RenderBox;
                currentHeight = box.size.height;
              },
              onVerticalDragUpdate: (update) {
                dragUpdate(update.primaryDelta);
              },
              onVerticalDragEnd: (details) {
                dragEnd();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    if (widget.shadow != null) widget.shadow,
                  ],
                  borderRadius: widget.borderRadius,
                ),
                child: Column(
                  children: <Widget>[
                    if (widget.header != null) widget.header,
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: widget.listViewPadding,
                        physics: NeverScrollableScrollPhysics(),
                        children: widget.children,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void dragUpdate(double delta) {
    if (delta < 0 && isAtMax()) {
      _scrollController.jumpTo(
        _scrollController.position.pixels - delta,
      );
    } else if (delta > 0 && isAtMax() && _scrollController.position.pixels > 0) {
      _scrollController.jumpTo(
        _scrollController.position.pixels - delta,
      );
    } else {
      currentHeight -= delta;
      setState(() {
        if (currentHeight < minDrawerHeight) {
          currentHeight = minDrawerHeight;
        } else if (currentHeight > maxDrawerHeight) {
          currentHeight = maxDrawerHeight;
        }
      });
    }
  }

  void dragEnd() {
    dragging = false;
    if (widget.snap == true) {
      double endHeight;
      double lastStop = widget.stops.first;
      for (double stop in widget.stops) {
        if (lastStop == stop) continue;
        if (currentHeight <= stop * height) {
          if (currentHeight >= (stop - lastStop) / 2 * height + lastStop * height) {
            endHeight = stop;
            break;
          } else {
            endHeight = lastStop;
            break;
          }
        } else {
          lastStop = stop;
        }
      }

      setState(() {
        currentHeight = height * endHeight;
      });
    }
  }

  bool isAtMax() {
    return currentHeight >= maxDrawerHeight;
  }

  bool isAtMin() {
    return currentHeight <= minDrawerHeight;
  }
}

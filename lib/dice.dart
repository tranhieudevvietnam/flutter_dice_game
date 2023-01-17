import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

class Dice extends StatefulWidget {
  const Dice({super.key});

  @override
  State<Dice> createState() => _DiceState();
}

class _DiceState extends State<Dice> with SingleTickerProviderStateMixin {
  late Object dice;
  late AnimationController _animationController;
  late CurvedAnimation _curvedAnimation;
  Vector3 values = Vector3.all(0);

  Offset offset = Offset.zero;

  Timer? _timer;
  ValueNotifier<int> count = ValueNotifier(0);
  final int _milliseconds = 2000;

  List<int> counts = [1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    dice = Object(fileName: "assets/dice04/dice.obj", scale: Vector3.all(0.75));
    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: _milliseconds));

    _curvedAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.decelerate)
          ..addListener(() {
            _updateDiceRotation();
          });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _curvedAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
                top: 0,
                left: 0,
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: listRow(listWidget: [], index: 0),
                )),
            Positioned(
              left: 0,
              bottom: 20,
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              child: Container(
                color: Colors.black,
                child: ScaleWidget(
                  animationParentController: _animationController,
                  child: GestureDetector(
                    onTap: () {
                      /* 
                      flow 1:  3-6-4-1 -> chiều dọc
                      flow 2:  3-2-4-5 -> chiều ngang
                       >>>>>> cách nhau 90
                      */

                      count.value += 1;
                      if (_timer != null) {
                        _timer!.cancel();
                        _timer = null;
                      }

                      _timer = Timer(
                        const Duration(seconds: 1),
                        () {
                          _animationController.duration = Duration(
                              milliseconds:
                                  (_milliseconds * count.value).toInt());
                          values.setValues(
                              getRandomNumb() * count.value,
                              getRandomNumb() * count.value,
                              getRandomNumb() * count.value);

                          debugPrint("values: ${values.toString()}");

                          if (_animationController.isDismissed) {
                            _animationController.forward();
                          } else {
                            _animationController.reset();
                            _animationController.forward();
                          }
                          count.value = 0;
                        },
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _curvedAnimation,
                      builder: (context, child) {
                        return Cube(
                          interactive: true,
                          onSceneCreated: (scene) {
                            scene.camera.zoom = 5;
                            scene.world.add(dice);
                            // scene.camera.position.setValues(-50, 0, 0);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: ValueListenableBuilder(
                valueListenable: count,
                builder: (context, value, child) {
                  if (value > 0) {
                    return Text(
                      value.toString(),
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getRandomNumb() {
    List<int> listData = [90, 180, 270, 360];
    int rand = Random().nextInt(4);
    debugPrint(listData[rand].toDouble().toString());
    return listData[rand].toDouble();
  }

  double getRandomCountScroll() {
    int rand = Random().nextInt(5) + 1;
    debugPrint(rand.toDouble().toString());
    return rand.toDouble();
  }

  // double getRandomNumb(int max) {
  //   int rand = Random().nextInt(max);
  //   while (rand % 90 != 0) {
  //     rand = Random().nextInt(max);
  //   }
  //   debugPrint(rand.toDouble().toString());
  //   return rand.toDouble();
  // }

  void _updateDiceRotation() {
    dice.rotation.setValues(values.x * _curvedAnimation.value,
        values.y * _curvedAnimation.value, values.z * _curvedAnimation.value);
    dice.updateTransform();
  }

  List<Widget> listRow({required List<Widget> listWidget, required int index}) {
    List<Widget> listView = [];
    int i = 0;
    while (i < counts.length && i < 3) {
      listView.add(itemWidget("${i + index}"));
      i++;
    }
    listWidget.add(Row(
      children: listView,
    ));
    if (i + index < counts.length) {
      return listRow(listWidget: listWidget, index: i + index);
    } else {
      return listWidget;
    }
  }

  Widget itemWidget(String title) {
    return Expanded(child: Center(child: Text(title)));
  }
}

class ScaleWidget extends StatefulWidget {
  final Widget child;
  final AnimationController animationParentController;
  const ScaleWidget(
      {super.key,
      required this.animationParentController,
      required this.child});

  @override
  State<ScaleWidget> createState() => _ScaleWidgetState();
}

class _ScaleWidgetState extends State<ScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> animation;
  bool stopAnimation = true;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && stopAnimation == false) {
              _animationController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _animationController.forward();
            }
          });

    widget.animationParentController.addStatusListener((status) {
      debugPrint("animationParentController: ->>> ${status.name}");
      if (status == AnimationStatus.forward) {
        stopAnimation = false;
        _animationController.forward();
      } else {
        stopAnimation = true;
        _animationController.stop();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleContainer(
      controller: animation,
      child: widget.child,
    );
  }
}

class ScaleContainer extends AnimatedWidget {
  final Widget child;
  const ScaleContainer({
    super.key,
    required this.child,
    required Animation<double> controller,
  }) : super(listenable: controller);
  static final _scaleTween = Tween<double>(begin: 1.0, end: 0.5);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Transform.scale(
      scale: _scaleTween.evaluate(animation),
      child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: child),
    );
  }
}

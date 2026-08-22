import 'package:flutter/material.dart';

class AppAddFab extends StatelessWidget {
  final String routeName;

  const AppAddFab({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.of(context).pushNamed(routeName),
      child: const Icon(Icons.add),
    );
  }
}

class AppFabAboveNavLocation extends FloatingActionButtonLocation {
  final double margin;

  const AppFabAboveNavLocation({this.margin = 10});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset endFloatOffset = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    return Offset(endFloatOffset.dx, endFloatOffset.dy - margin);
  }
}
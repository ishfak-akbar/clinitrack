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
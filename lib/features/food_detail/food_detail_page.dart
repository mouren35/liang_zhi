import 'package:flutter/material.dart';

class FoodDetailPage extends StatelessWidget {
  const FoodDetailPage({required this.foodId, super.key});

  final String foodId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('食物详情：$foodId')));
  }
}

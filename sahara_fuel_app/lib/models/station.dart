import 'package:flutter/material.dart';

class StationData {
  final String name;
  final IconData icon;
  final double balance;
  final int change;
  final Color color;
  final List<String> farms;
  final List<SubStation>? subStations;
  final int generatorHours;
  final int heaterHours;

  StationData({
    required this.name,
    required this.icon,
    required this.balance,
    required this.change,
    required this.color,
    required this.farms,
    this.subStations,
    this.generatorHours = 0,
    this.heaterHours = 0,
  });
}

class SubStation {
  final String name;
  final List<String> farms;
  SubStation({required this.name, required this.farms});
}


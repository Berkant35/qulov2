import 'package:flutter/material.dart';

class PlanFeature {
  final String? icon;
  final Widget? iconWidget;
  final String text;
  const PlanFeature(this.icon, this.text) : iconWidget = null;
  const PlanFeature.widget(this.iconWidget, this.text) : icon = null;
}

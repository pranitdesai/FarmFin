import 'package:flutter/material.dart';

double responsiveFont(BuildContext context, double baseFontSize) {
  final width = MediaQuery.of(context).size.width;
  return baseFontSize * (width / 375); // 375 = base reference width
}

double responsiveWidth(BuildContext context, double baseWidth) {
  final screenWidth = MediaQuery.of(context).size.width;
  return baseWidth * (screenWidth / 375);
}

double responsiveHeight(BuildContext context, double baseHeight) {
  final screenHeight = MediaQuery.of(context).size.height;
  return baseHeight * (screenHeight / 812); // 812 = base reference height
}

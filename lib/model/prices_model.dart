import 'package:fl_chart/fl_chart.dart';

class CryptoChart {
  final FlSpot spot;

  CryptoChart({
    required this.spot,
  });
  factory CryptoChart.fromJson(Map<String, dynamic> json) {
  return CryptoChart(
    spot: json['prices'],
  );
}


  Map<String, dynamic> toJson() {
    return {

    };
  }
}
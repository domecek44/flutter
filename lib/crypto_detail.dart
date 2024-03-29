import 'dart:convert';
import 'package:cryptoapp/main.dart';
import 'package:cryptoapp/model/prices_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CryptoDetailPage extends StatefulWidget {
  final Crypto crypto;

  const CryptoDetailPage({super.key, required this.crypto});

  @override
  State<CryptoDetailPage> createState() => _CryptoDetailPageState();
}

class _CryptoDetailPageState extends State<CryptoDetailPage> {
  List<FlSpot> chartData = [];

  Future<void> _fetchCryptos() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'crypto_${widget.crypto.name.toLowerCase()}_prices';

    if (prefs.containsKey(cacheKey)) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final result = json.decode(cachedData);
        final List<dynamic> prices = result['prices'];
        chartData = prices.map((price) => FlSpot(price[0].toDouble(), price[1].toDouble())).toList();
        _processChartData();
        return;
      }
    }

    final response = await http.get(Uri.parse('https://api.coingecko.com/api/v3/coins/${widget.crypto.name.toLowerCase()}/market_chart?vs_currency=usd&days=1'));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final List<dynamic> prices = result['prices'];
      chartData = prices.map((price) => FlSpot(price[0].toDouble(), price[1].toDouble())).toList();
      _processChartData();

      await prefs.setString(cacheKey, json.encode(result));
    } else {
      print('Failed to load cryptocurrencies');
    }
  }

  void _processChartData() {
    DateTime now = DateTime.now();
    int nowTimestamp = now.millisecondsSinceEpoch;
    int intervalMilliseconds = 600000;
    int maxDataPoints = 50;

    setState(() {
      int lastTimestamp = 0;
      chartData = chartData.where((element) {
        bool shouldInclude = element.x < nowTimestamp && (element.x - lastTimestamp) > intervalMilliseconds;
        if (shouldInclude) {
          lastTimestamp = element.x.toInt();
        }
        return shouldInclude;
      }).toList();

      if (chartData.length > maxDataPoints) {
        chartData = chartData.sublist(chartData.length - maxDataPoints);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCryptos();
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.crypto.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(widget.crypto.iconUrl, width: 100),
            SizedBox(height: 20),
            Text('Price: \$${widget.crypto.price.toStringAsFixed(2)}', style: TextStyle(fontFamily: 'Satoshi' ,fontSize: 24)),
            SizedBox(height: 10),
            Text(
           '24h Change: ${widget.crypto.change24h.toStringAsFixed(2)}%',
          style: TextStyle(
             fontFamily: 'Satoshi',
             fontSize: 20,
            color: widget.crypto.change24h < 0 ? Colors.red : Colors.green, 
  ),
),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueAccent,
                       getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                       final formattedValue = touchedSpot.y.toStringAsFixed(2);
                       return LineTooltipItem(
                      '\$${formattedValue}',
                      const TextStyle(color: Colors.white),
                        );
                         }).toList();
                      },
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    },
                    handleBuiltInTouches: true,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[400]!, width: 1),
                  ),
                  minX: chartData.isNotEmpty ? chartData.first.x : 0,
                  maxX: chartData.isNotEmpty ? chartData.last.x : 0,
                  minY: chartData.isNotEmpty ? chartData.reduce((value, element) => value.y < element.y ? value : element).y : 0,
                  maxY: chartData.isNotEmpty ? chartData.reduce((value, element) => value.y > element.y ? value : element).y : 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
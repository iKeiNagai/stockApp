import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';

class PortfolioGraph extends StatefulWidget {
  final List<QueryDocumentSnapshot> positions;

  const PortfolioGraph({Key? key, required this.positions}) : super(key: key);

  @override
  State<PortfolioGraph> createState() => _PortfolioGraphState();
}

class _PortfolioGraphState extends State<PortfolioGraph> {
  List<FlSpot> _spots = [];
  double _maxY = 0;
  double _minY = 0;
  bool _isLoading = true;
  String selectedTimeframe = '1D';

  @override
  void initState() {
    super.initState();
    _loadGraphData();
  }

  @override
  void didUpdateWidget(PortfolioGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.positions != oldWidget.positions) {
      _loadGraphData();
    }
  }

  Future<void> _loadGraphData() async {
    if (widget.positions.isEmpty) {
      setState(() {
        _spots = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<DateTime, double> dailyValues = {};

      for (var position in widget.positions) {
        final data = position.data() as Map<String, dynamic>;
        final ticker = data['ticker'];
        final quantity = data['quantity'].toDouble();

        YahooFinanceResponse response =
            await YahooFinanceDailyReader().getDailyDTOs(ticker);

        for (var candle in response.candlesData) {
          final date = candle.date;
          final close = candle.close;
          final value = close * quantity;
          dailyValues.update(
            date,
            (existing) => existing + value,
            ifAbsent: () => value,
          );
        }
      }

      // Convert to sorted list of FlSpots
      final sortedDates = dailyValues.keys.toList()..sort();
      _spots = sortedDates.map((date) {
        return FlSpot(
          date.millisecondsSinceEpoch.toDouble(),
          dailyValues[date]!,
        );
      }).toList();

      if (_spots.isNotEmpty) {
        _maxY = _spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
        _minY = _spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      }
    } catch (e) {
      print('Error loading graph data: $e');
      _spots = [];
    }

    setState(() => _isLoading = false);
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (selectedTimeframe) {
      case '1D':
        return now.subtract(Duration(days: 1));
      case '1W':
        return now.subtract(Duration(days: 7));
      case '1M':
        return now.subtract(Duration(days: 30));
      case '3M':
        return now.subtract(Duration(days: 90));
      case '1Y':
        return now.subtract(Duration(days: 365));
      case 'ALL':
        return now.subtract(Duration(days: 365 * 5));
      default:
        return now.subtract(Duration(days: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_spots.isEmpty) {
      return Container(
        height: 300,
        child: Center(child: Text('No data available')),
      );
    }

    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    color: _spots.last.y >= _spots.first.y
                        ? Color(0xFF50FA7B) // Green for positive
                        : Color(0xFFFF79C6), // Pink for negative
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (_spots.last.y >= _spots.first.y
                              ? Color(0xFF50FA7B)
                              : Color(0xFFFF79C6))
                          .withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black.withOpacity(0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '\$${spot.y.toStringAsFixed(2)}',
                          TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
                minY: _minY * 0.95,
                maxY: _maxY * 1.05,
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var timeframe in ['1D', '1W', '1M', '3M', '1Y', 'ALL'])
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedTimeframe = timeframe;
                      _loadGraphData();
                    });
                  },
                  child: Text(
                    timeframe,
                    style: TextStyle(
                      color: selectedTimeframe == timeframe
                          ? Color(0xFF50FA7B)
                          : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

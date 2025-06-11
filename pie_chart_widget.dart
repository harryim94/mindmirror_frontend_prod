import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EmotionPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> emotionData;
  final int total;
  final List<Color> colors;

  const EmotionPieChart({
    super.key,
    required this.emotionData,
    required this.total,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: List.generate(emotionData.length, (i) {
                final e = emotionData[i];
                return PieChartSectionData(
                  value: e["count"]?.toDouble() ?? 0.0,
                  color: colors[i % colors.length],
                  title: "${e["percentage"]}%",
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'records',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

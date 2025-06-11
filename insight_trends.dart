import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DailyMoodChart extends StatelessWidget {
  final Map<String, double> moodData;

  const DailyMoodChart({super.key, required this.moodData});

  @override
  Widget build(BuildContext context) {
    // ✅ 날짜순으로 정렬
    final sortedEntries = moodData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final keys = sortedEntries.map((e) => e.key).toList();
    final values = sortedEntries.map((e) => e.value).toList();

    final spots = List.generate(keys.length, (index) {
      return FlSpot(index.toDouble(), values[index]);
    });

    final average = values.isNotEmpty
        ? values.reduce((a, b) => a + b) / values.length
        : 0.0;

    // ✅ Y축 자동 확장
    final minY = (values.reduce((a, b) => a < b ? a : b) - 0.2).clamp(-1.2, -0.5);
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 0.2).clamp(0.5, 1.2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            minX: 0,
            maxX: (keys.length - 1).toDouble(),
            clipData: FlClipData.all(),
            lineTouchData: LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                curveSmoothness: 0.15,
                spots: spots,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
                color: Colors.blueAccent,
              )
            ],
            titlesData: FlTitlesData(
            leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 90,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != -1 && value != 0 && value != 1) return const SizedBox.shrink();
                switch (value.round()) {
                  case 1:
                    return const Text("😊 Positive", overflow: TextOverflow.ellipsis);
                  case 0:
                    return const Text("😐 Neutral", overflow: TextOverflow.ellipsis);
                  case -1:
                    return const Text("😞 Negative", overflow: TextOverflow.ellipsis);
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: (keys.length / 5).floorToDouble().clamp(1.0, 10.0),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < keys.length) {
                      final parts = keys[index].split('-'); // yyyy-mm-dd
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "${int.parse(parts[1])}/${int.parse(parts[2])}",
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: true),
            extraLinesData: values.length > 1
                ? ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: average,
                      color: Colors.purpleAccent,
                      strokeWidth: 1,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.centerRight,
                        labelResolver: (_) => "Avg",
                        style: const TextStyle(fontSize: 10, color: Colors.purple),
                      ),
                    )
                  ])
                : ExtraLinesData(horizontalLines: []),
          ),
        ),
      ),
    );
  }
}
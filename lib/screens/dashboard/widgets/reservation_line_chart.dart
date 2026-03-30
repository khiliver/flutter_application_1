import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/reservation.dart';

class ReservationLineChart extends StatelessWidget {
  const ReservationLineChart({
    super.key,
    required this.weekDates,
    required this.types,
    required this.spotsByType,
    required this.colorsByType,
    required this.chartMaxY,
    required this.yInterval,
    required this.onPickCollegeFilter,
    required this.onPickDate,
  });

  final List<DateTime> weekDates;
  final List<ReservationType> types;
  final Map<ReservationType, List<FlSpot>> spotsByType;
  final Map<ReservationType, Color> colorsByType;
  final double chartMaxY;
  final double yInterval;
  final VoidCallback onPickCollegeFilter;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Reservation Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onPickCollegeFilter,
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by college',
            ),
            IconButton(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Select date',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ShadCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final dateIndex = spot.x.toInt();
                            final date = weekDates[dateIndex];
                            final typeLabel = types[spot.barIndex].label;
                            return LineTooltipItem(
                              '${date.month}/${date.day}\n$typeLabel: ${spot.y.toInt()}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= weekDates.length) {
                              return const SizedBox.shrink();
                            }
                            final date = weekDates[index];
                            return Text(
                              '${date.month}/${date.day}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                          interval: 1,
                        ),
                      ),
                    ),
                    minX: 0,
                    maxX: (weekDates.length - 1).toDouble(),
                    minY: 0,
                    maxY: chartMaxY,
                    lineBarsData: types
                        .map(
                          (type) => LineChartBarData(
                            spots: spotsByType[type]!,
                            isCurved: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: colorsByType[type]!.withAlpha(
                                (0.12 * 255).round(),
                              ),
                            ),
                            color: colorsByType[type]!,
                            barWidth: 3,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: types
                    .map(
                      (type) => _LegendItem(
                        color: colorsByType[type]!,
                        label: type.label,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

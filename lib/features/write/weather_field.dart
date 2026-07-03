import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';

/// "오늘의 날씨" picker: a labelled horizontal row of tappable weather chips.
/// Tapping the selected one clears it (via [toggledWeather]). Standalone so the
/// write screen stays within its line budget.
class WeatherField extends StatelessWidget {
  const WeatherField({super.key, required this.value, required this.onChanged});

  final Weather? value;
  final ValueChanged<Weather?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('오늘의 날씨',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final w in Weather.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _WeatherChip(
                    weather: w,
                    selected: value == w,
                    onTap: () => onChanged(toggledWeather(value, w)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip(
      {required this.weather, required this.selected, required this.onTap});

  final Weather weather;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(weather.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(weather.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

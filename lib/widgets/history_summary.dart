import 'package:flutter/material.dart';
import 'glass_card.dart';

class SummaryItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const SummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accentColor = const Color(0xFF38BDF8),
  });
}

/// 3 kotak ringkasan kecil bergaya kaca di atas tabel riwayat
class HistorySummary extends StatelessWidget {
  final List<SummaryItem> items;

  const HistorySummary({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCard(item),
              );
            }).toList(),
          );
        }

        return Row(
          children: items.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _buildCard(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCard(SummaryItem item) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.accentColor.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Icon(item.icon, size: 18, color: item.accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: item.accentColor.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

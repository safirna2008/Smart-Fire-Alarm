import 'package:flutter/material.dart';

enum NavTab {
  dashboard,
  gas,
  flame,
  temp,
  buzzer,
  fan,
  led,
}

/// Menu navigasi atas (top navigation) berbentuk tab chip horizontal bergaya kaca.
/// Di mobile, menu dapat digeser ke samping (scrollable).
/// Tab aktif ditampilkan dengan highlight yang lebih terang.
class TopNav extends StatelessWidget {
  final NavTab activeTab;
  final ValueChanged<NavTab> onTabSelected;

  const TopNav({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  static const List<_TabItem> _items = [
    _TabItem(tab: NavTab.dashboard, label: 'Dashboard', icon: Icons.dashboard_rounded),
    _TabItem(tab: NavTab.gas, label: 'Gas MQ2', icon: Icons.cloud_queue_rounded),
    _TabItem(tab: NavTab.flame, label: 'Api IR', icon: Icons.local_fire_department_rounded),
    _TabItem(tab: NavTab.temp, label: 'Suhu DHT22', icon: Icons.thermostat_rounded),
    _TabItem(tab: NavTab.buzzer, label: 'Buzzer', icon: Icons.volume_up_rounded),
    _TabItem(tab: NavTab.fan, label: 'Kipas', icon: Icons.mode_fan_off_rounded),
    _TabItem(tab: NavTab.led, label: 'LED Status', icon: Icons.lightbulb_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _items.map((item) {
            final bool isActive = item.tab == activeTab;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () => onTabSelected(item.tab),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withOpacity(0.24) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? Colors.white.withOpacity(0.35) : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 15,
                        color: isActive ? Colors.white : Colors.white.withOpacity(0.65),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? Colors.white : Colors.white.withOpacity(0.75),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final NavTab tab;
  final String label;
  final IconData icon;

  const _TabItem({
    required this.tab,
    required this.label,
    required this.icon,
  });
}

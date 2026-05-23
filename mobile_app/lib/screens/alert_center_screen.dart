import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisisync/config/theme.dart';
import 'package:crisisync/services/crisis_provider.dart';

class AlertCenterScreen extends StatelessWidget {
  const AlertCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CrisisProvider>(context);
    final alert = provider.publicAlert;
    final hasAlert = alert.isNotEmpty;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active broadcasts header
              const Text(
                "Active Evacuation & Safety Alerts",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
              ),
              const SizedBox(height: 10),
              
              if (hasAlert)
                _buildActiveBroadcastCard(alert)
              else
                _buildNoAlertsCard(),

              const SizedBox(height: 24),
              const Text(
                "General Public Safety Guidelines",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
              ),
              const SizedBox(height: 10),
              _buildSafetyGuidelinesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBroadcastCard(Map<String, dynamic> alert) {
    final isCritical = alert['title'] == "CRITICAL ALERT";
    final cardColor = isCritical ? AppTheme.alertRed : AppTheme.warningYellow;

    return Container(
      width: double.infinity,
      decoration: AppTheme.glassCardDecoration(borderColor: cardColor.withOpacity(0.3)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.campaign_rounded, color: cardColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title'] ?? 'Emergency Alert',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cardColor),
                    ),
                    Text(
                      "Transmitted via: ${alert['channel'] ?? 'Cellular Grid'}",
                      style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.black12),
          Text(
            alert['message'] ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark, height: 1.4),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "Timestamp: ${alert['timestamp'] ?? ''}",
              style: const TextStyle(fontSize: 10, color: AppTheme.textLight, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAlertsCard() {
    return Container(
      width: double.infinity,
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 48),
          SizedBox(height: 12),
          Text(
            "No Active Public Alerts",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
          ),
          SizedBox(height: 4),
          Text(
            "Metropolitan broadcast alerts are currently clear. All routes running within normal parameters.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyGuidelinesList() {
    final guidelines = [
      {
        "title": "Flash Floods & Waterlogging",
        "desc": "Avoid driving through water-logged underpasses. Reroute via highway links. Keep phones charged and stay on high ground.",
        "icon": Icons.water_drop_rounded,
        "color": AppTheme.secondary
      },
      {
        "title": "Extreme Heatwaves",
        "desc": "Stay indoors between 11:00 AM and 04:00 PM. Drink water mixed with electrolytes. Wear loose light-colored clothing.",
        "icon": Icons.wb_sunny_rounded,
        "color": Colors.orange.shade700
      },
      {
        "title": "Accidents & Collision Scenes",
        "desc": "Clear pathways for emergency vehicles. Reroute 1km prior using designated detours. Do not crowd the collision site.",
        "icon": Icons.car_crash_rounded,
        "color": AppTheme.alertRed
      }
    ];

    return Column(
      children: guidelines.map((g) {
        final color = g['color'] as Color;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: AppTheme.glassCardDecoration(),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(g['icon'] as IconData, color: color, size: 24),
            ),
            title: Text(
              g['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                g['desc'] as String,
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight, height: 1.3),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

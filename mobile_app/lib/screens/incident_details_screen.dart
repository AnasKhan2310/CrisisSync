import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisisync/config/theme.dart';
import 'package:crisisync/services/crisis_provider.dart';
import 'package:crisisync/models/crisis_models.dart';

class IncidentDetailsScreen extends StatelessWidget {
  const IncidentDetailsScreen({super.key});

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
        return AppTheme.alertRed;
      case 'MEDIUM':
        return AppTheme.warningYellow;
      default:
        return AppTheme.secondary;
    }
  }

  Color _getActionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return AppTheme.accent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CrisisProvider>(context);
    final incident = provider.activeIncident;
    final simState = provider.simulationState;

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Incident Details")),
        body: const Center(
          child: Text("No active incident analysis available. Inject signals first."),
        ),
      );
    }

    final severityColor = _getSeverityColor(incident.severity);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Crisis Intelligence", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Severity Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: severityColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${incident.severity} SEVERITY",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Confidence: ${(incident.confidence * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                incident.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              Text(
                "Primary Location: ${incident.location} | Ingested: ${incident.timestamp}",
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              const SizedBox(height: 16),

              // AI Reasoning Panel
              const Text("AI Reasoning & Detection Synthesis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCardDecoration(color: Colors.white, opacity: 0.95),
                child: Text(
                  incident.reasoning,
                  style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textDark),
                ),
              ),
              const SizedBox(height: 20),

              // Affected Zones Grid
              const Text("Affected Metropolitan Zones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildZonesList(incident.affectedZones),
              const SizedBox(height: 20),

              // Generated Response Actions
              const Text("Recommended Response Strategy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildActionsList(incident.actions),
              const SizedBox(height: 24),

              // Simulation Metrics Section (Outcome Visuals)
              if (simState != null) ...[
                const Text("Simulation Outcomes & Impact Mitigation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildMetricsComparison(simState),
                const SizedBox(height: 16),
                _buildSimulationSteps(simState),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZonesList(List<AffectedZone> zones) {
    return Container(
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: zones.map((zone) {
          final zoneColor = _getSeverityColor(zone.severity);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(Icons.location_on_rounded, color: zoneColor),
            title: Text(zone.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: zoneColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: zoneColor.withOpacity(0.3)),
              ),
              child: Text(
                zone.severity,
                style: TextStyle(color: zoneColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionsList(List<ActionItem> actions) {
    return Container(
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: actions.map((action) {
          final statusColor = _getActionStatusColor(action.status);
          IconData actionIcon = Icons.pending_actions_rounded;
          if (action.assignedTo == "traffic_control") {
            actionIcon = Icons.traffic_rounded;
          } else if (action.assignedTo == "rescue_1122") {
            actionIcon = Icons.local_hospital_rounded;
          } else if (action.assignedTo == "alert_broadcast") {
            actionIcon = Icons.campaign_rounded;
          }

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(actionIcon, color: AppTheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action.description,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    action.status.toUpperCase().replaceAll("_", " "),
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsComparison(SimulationState sim) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildComparisonCard(
          "Traffic Congestion",
          "${sim.beforeCongestion}%",
          "${sim.afterCongestion}%",
          "-${sim.beforeCongestion - sim.afterCongestion}%",
          Colors.orange.shade700,
          Colors.green,
        ),
        _buildComparisonCard(
          "Emergency ETA",
          "${sim.beforeEta}m",
          "${sim.afterEta}m",
          "-${sim.beforeEta - sim.afterEta}m",
          AppTheme.alertRed,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildComparisonCard(
    String label,
    String before,
    String after,
    String diff,
    Color beforeColor,
    Color afterColor,
  ) {
    return Container(
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
          const Spacer(),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Before", style: TextStyle(fontSize: 9, color: AppTheme.textLight)),
                  Text(before, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: beforeColor)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.textLight),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("After", style: TextStyle(fontSize: 9, color: AppTheme.textLight)),
                  Text(after, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: afterColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "Improvement: $diff",
              style: TextStyle(color: afterColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationSteps(SimulationState sim) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.glassCardDecoration(color: const Color(0xFF1E2627)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Outcome Simulation Logs",
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sim.logs.map((log) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  log,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

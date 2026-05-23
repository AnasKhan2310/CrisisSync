import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisisync/config/theme.dart';
import 'package:crisisync/services/crisis_provider.dart';
import 'package:crisisync/models/crisis_models.dart';
import 'package:crisisync/screens/incident_details_screen.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ScrollController _logScrollController = ScrollController();

  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

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

  IconData _getIncidentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'urban_flooding':
        return Icons.water_drop_rounded;
      case 'heatwave':
        return Icons.wb_sunny_rounded;
      case 'road_blockage':
        return Icons.block_rounded;
      case 'accident':
        return Icons.car_crash_rounded;
      case 'infrastructure_failure':
        return Icons.construction_rounded;
      default:
        return Icons.report_problem_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CrisisProvider>(context);
    final activeInc = provider.activeIncident;

    // Trigger auto scroll to bottom of logs on new log arrival
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Telemetry Gauges / Cards
              _buildTelemetrySection(provider),
              const SizedBox(height: 20),

              // 2. Active incident panel
              const Text(
                "Active Metropolitan Status",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
              ),
              const SizedBox(height: 10),
              activeInc != null
                  ? _buildActiveIncidentCard(context, activeInc, provider)
                  : _buildStableIncidentCard(provider),
              const SizedBox(height: 24),

              // 3. AI Log Console Panel
              const Row(
                children: [
                  Icon(Icons.terminal_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "AI Monitoring Panel (Multi-Agent Logs)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildLogConsole(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetrySection(CrisisProvider provider) {
    final hasIncident = provider.activeIncident != null;
    final isFlooding = provider.activeIncident?.type == "urban_flooding";
    final isHeatwave = provider.activeIncident?.type == "heatwave";

    String threatText = "LOW / STABLE";
    Color threatColor = AppTheme.secondary;
    if (hasIncident) {
      if (provider.activeIncident!.severity == "HIGH") {
        threatText = "CRITICAL THREAT";
        threatColor = AppTheme.alertRed;
      } else {
        threatText = "MEDIUM THREAT";
        threatColor = AppTheme.warningYellow;
      }
    }

    // Dynamic Traffic Flow Percentage
    int trafficFlow = 98;
    if (hasIncident) {
      if (provider.isSimulating) {
        trafficFlow = 54; // Dropped during ongoing incident
      } else if (provider.simulationState != null) {
        trafficFlow = provider.simulationState!.afterCongestion; // Result of rerouting
      } else {
        trafficFlow = provider.activeIncident!.severity == "HIGH" ? 45 : 70;
      }
    }

    // Weather status description
    String weatherText = "Normal: 28°C";
    IconData weatherIcon = Icons.cloud_queue_rounded;
    Color weatherColor = AppTheme.secondary;

    if (isFlooding) {
      weatherText = "Heavy Rain Warning";
      weatherIcon = Icons.thunderstorm_rounded;
      weatherColor = AppTheme.alertRed;
    } else if (isHeatwave) {
      weatherText = "Extreme Heat: 45°C";
      weatherIcon = Icons.wb_sunny_rounded;
      weatherColor = AppTheme.alertRed;
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _buildTelemetryCard(
          "Threat Index",
          threatText,
          threatColor,
          Icons.shield_outlined,
        ),
        _buildTelemetryCard(
          "Traffic Flow",
          "$trafficFlow%",
          trafficFlow > 80
              ? Colors.green
              : (trafficFlow > 50 ? AppTheme.warningYellow : AppTheme.alertRed),
          Icons.traffic_outlined,
        ),
        _buildTelemetryCard(
          "Weather Grid",
          weatherText,
          weatherColor,
          weatherIcon,
        ),
      ],
    );
  }

  Widget _buildTelemetryCard(String title, String subtitle, Color accentColor, IconData icon) {
    return Container(
      decoration: AppTheme.glassCardDecoration(
        opacity: 0.9,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveIncidentCard(BuildContext context, Incident incident, CrisisProvider provider) {
    final severityColor = _getSeverityColor(incident.severity);
    final isResolving = provider.isSimulating;

    return Container(
      decoration: AppTheme.glassCardDecoration(borderColor: severityColor.withOpacity(0.3)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIncidentIcon(incident.type), color: severityColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Location: ${incident.location} | Status: ${incident.status.toUpperCase()}",
                      style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.black12),
          
          // Agents Pipeline Progress Display
          _buildPipelineProgress(provider.activeStep),
          const SizedBox(height: 18),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      incident.severity,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Confidence: ${(incident.confidence * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IncidentDetailsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const Text("View AI Analysis", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStableIncidentCard(CrisisProvider provider) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(
                Icons.radar_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Metropolitan Area Normal",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            "Orchestration logs listening to social feeds, weather grids, and traffic sensors.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
          const SizedBox(height: 16),
          // Short list of history if any
          if (provider.incidentsHistory.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Resolved Incidents:",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textDark),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.incidentsHistory.length > 2 ? 2 : provider.incidentsHistory.length,
              itemBuilder: (context, index) {
                final hist = provider.incidentsHistory[provider.incidentsHistory.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(_getIncidentIcon(hist.type), color: AppTheme.textLight, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hist.title,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "Resolved",
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPipelineProgress(String? activeStep) {
    // List of steps matching our multi-agent pipeline
    final pipelineSteps = [
      {"id": "signal_intake", "label": "Intake"},
      {"id": "crisis_detection", "label": "Detect"},
      {"id": "severity_analysis", "label": "Analyze"},
      {"id": "response_planning", "label": "Plan"},
      {"id": "outcome_simulation", "label": "Simulate"},
    ];

    int activeIdx = -1;
    if (activeStep != null) {
      activeIdx = pipelineSteps.indexWhere((step) => step["id"] == activeStep);
      // Fallbacks for intermediate steps mapping to simulation or planning
      if (activeIdx == -1) {
        if (activeStep == "route_optimization" || activeStep == "emergency_dispatch" || activeStep == "alert_broadcasting") {
          activeIdx = 3; // response_planning completed / in progress
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "AI Orchestration Pipeline:",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(pipelineSteps.length, (index) {
            final isCompleted = index < activeIdx;
            final isCurrent = index == activeIdx;
            final color = isCurrent
                ? AppTheme.accent
                : (isCompleted ? AppTheme.primary : Colors.grey.shade300);

            return Expanded(
              child: Column(
                children: [
                  Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pipelineSteps[index]["label"]!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? AppTheme.accent : AppTheme.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLogConsole(CrisisProvider provider) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2627),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: provider.logs.isEmpty
          ? const Center(
              child: Text(
                "Waiting for multi-agent system activity...",
                style: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace'),
              ),
            )
          : Scrollbar(
              controller: _logScrollController,
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: provider.logs.length,
                itemBuilder: (context, index) {
                  final log = provider.logs[index];
                  Color levelColor = Colors.grey;
                  if (log.level == "ERROR") {
                    levelColor = AppTheme.alertRed;
                  } else if (log.level == "WARNING") {
                    levelColor = AppTheme.warningYellow;
                  } else if (log.level == "AGENT") {
                    levelColor = AppTheme.accent;
                  } else if (log.level == "INFO") {
                    levelColor = Colors.greenAccent;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text: "[${log.timestamp}] ",
                            style: const TextStyle(color: Colors.white30),
                          ),
                          TextSpan(
                            text: "[${log.agent ?? 'SYSTEM'}] ",
                            style: TextStyle(color: levelColor, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: log.message,
                            style: const TextStyle(color: Color(0xFFE2EFEF)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

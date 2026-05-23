import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisisync/config/theme.dart';
import 'package:crisisync/services/crisis_provider.dart';

class SimulationPanelScreen extends StatefulWidget {
  const SimulationPanelScreen({super.key});

  @override
  State<SimulationPanelScreen> createState() => _SimulationPanelScreenState();
}

class _SimulationPanelScreenState extends State<SimulationPanelScreen> {
  String _selectedScenario = "flooding_g10";

  final Map<String, List<Map<String, dynamic>>> _scenarios = {
    "flooding_g10": [
      {"source": "social", "content": "G-10 mein pani bhar gaya hai, gaariyan phans gayi hain!"},
      {"source": "weather", "content": "HEAVY RAIN WARNING: Severe thunderstorm active over Sector G-10. Accumulation up to 60mm."},
      {"source": "traffic", "content": "Traffic bottleneck: 3km congestion spike near G-10 Double Road."}
    ],
    "flooding_georgetown": [
      {"source": "social", "content": "Flash flood happening at George Town for past 30 mins, drainage is fully blocked."},
      {"source": "social", "content": "Cars stuck due to flood under George Town flyover. Water levels rising rapidly."},
      {"source": "weather", "content": "Heavy rainfall alert for George Town metropolitan corridor."},
      {"source": "traffic", "content": "Traffic congestion spike detected around George Town main underpass."}
    ],
    "accident_saddar": [
      {"source": "social", "content": "Saddar Metro Station Chowk pe gaariyon ki takkar hui hai, road completely block hai."},
      {"source": "traffic", "content": "Accident anomaly: Murree Road Saddar corridor choked. Speed reduced to 5 km/h."},
      {"source": "emergency_report", "content": "Caller reports 2-car collision near Saddar Commercial Plaza. Medical help needed."}
    ],
    "heatwave": [
      {"source": "weather", "content": "MET ADV_04: Extreme heatwave warning. Ambient temperature peaking at 45.8C."},
      {"source": "social", "content": "Severe heat in Saddar commercial center. People collapsing due to sunstroke. We need cooling camps!"}
    ]
  };

  String _getScenarioName(String key) {
    switch (key) {
      case "flooding_g10":
        return "Urban Flooding (G-10 Sector - Mixed Language)";
      case "flooding_georgetown":
        return "Urban Flooding (George Town Corridor)";
      case "accident_saddar":
        return "Road Collision (Saddar Metro Chowk - Roman Urdu)";
      case "heatwave":
        return "Extreme Heatwave Warning";
      default:
        return key;
    }
  }

  IconData _getScenarioIcon(String key) {
    switch (key) {
      case "flooding_g10":
      case "flooding_georgetown":
        return Icons.water_drop_rounded;
      case "accident_saddar":
        return Icons.car_crash_rounded;
      case "heatwave":
        return Icons.wb_sunny_rounded;
      default:
        return Icons.rss_feed_rounded;
    }
  }

  void _triggerSimulation(CrisisProvider provider) async {
    final signals = _scenarios[_selectedScenario];
    if (signals != null) {
      final success = await provider.startSimulation(signals);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "Emergency injected. Multi-agent pipeline starting..."
                : "Failed to trigger simulation. Check backend connection."),
            backgroundColor: success ? AppTheme.primary : AppTheme.alertRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CrisisProvider>(context);
    final isSimulating = provider.isSimulating;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel header
              const Text(
                "Crisis Ingestion Control Board",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
              ),
              const SizedBox(height: 4),
              const Text(
                "Inject simulated signals directly into the Antigravity multi-agent intake system to verify event detection and response workflows.",
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              const SizedBox(height: 20),

              // Dropdown Selection Card
              Container(
                decoration: AppTheme.glassCardDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Simulation Template:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedScenario,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _scenarios.keys.map((key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Row(
                            children: [
                              Icon(_getScenarioIcon(key), color: AppTheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(_getScenarioName(key), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: isSimulating
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedScenario = val;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    
                    // Signals List Preview
                    const Text(
                      "Preview Input Signals to Ingest:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 6),
                    ...(_scenarios[_selectedScenario] ?? []).map((sig) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black.withOpacity(0.04)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sig['source'].toUpperCase(),
                                style: const TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sig['content'],
                                style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    
                    // Trigger Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isSimulating ? null : () => _triggerSimulation(provider),
                        icon: isSimulating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.play_circle_fill_rounded),
                        label: Text(isSimulating ? "Simulation in progress..." : "Deploy Response Orchestrator"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Simulation Stats (Only shown when active simulation status exists)
              if (provider.activeIncident != null) ...[
                const Text(
                  "Active Pipeline Execution Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                ),
                const SizedBox(height: 10),
                _buildActiveStatusCard(provider),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveStatusCard(CrisisProvider provider) {
    final status = provider.activeIncident!.status;
    final step = provider.activeStep;

    return Container(
      width: double.infinity,
      decoration: AppTheme.glassCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Incident ID: ${provider.activeIncident!.id}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: status == "mitigated" ? Colors.green : AppTheme.alertRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Text("Current Pipeline Step: ", style: TextStyle(fontSize: 13)),
              Text(
                step?.toUpperCase().replaceAll('_', ' ') ?? 'IDLE',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.isSimulating)
            const LinearProgressIndicator(
              color: AppTheme.accent,
              backgroundColor: Colors.black12,
            )
          else ...[
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text("All coordinated agents completed execution.", style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                provider.clearActive();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: AppTheme.textDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text("Clear Active Simulation", style: TextStyle(fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }
}

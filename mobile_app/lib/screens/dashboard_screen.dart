import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisisync/config/theme.dart';
import 'package:crisisync/services/crisis_provider.dart';
import 'package:crisisync/screens/dashboard_view.dart';
import 'package:crisisync/screens/map_screen.dart';
import 'package:crisisync/screens/alert_center_screen.dart';
import 'package:crisisync/screens/simulation_panel_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const MapScreen(),
    const AlertCenterScreen(),
    const SimulationPanelScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize provider websocket connections
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CrisisProvider>(context, listen: false).initialize();
    });
  }

  void _showIpConfigDialog(BuildContext context, CrisisProvider provider) {
    final TextEditingController controller = TextEditingController(text: provider.backendHost);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Configure Backend Host"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your FastAPI server host/IP address:"),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "127.0.0.1:8000",
                labelText: "Host Address",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.updateBackendHost(controller.text);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CrisisProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.radar_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CrisisSync",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  "AI Urban Incident Control",
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        elevation: 4,
        actions: [
          // Connection Status indicator
          GestureDetector(
            onTap: () => _showIpConfigDialog(context, provider),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: provider.isConnected ? AppTheme.accent : Colors.redAccent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: provider.isConnected ? AppTheme.accent : Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: provider.isConnected ? AppTheme.accent : Colors.redAccent,
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.isConnected ? "LIVE" : "OFFLINE",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Live Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active_outlined),
              activeIcon: Icon(Icons.notifications_active_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Simulation',
            ),
          ],
        ),
      ),
    );
  }
}

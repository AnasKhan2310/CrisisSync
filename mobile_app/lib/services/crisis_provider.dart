import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crisisync/models/crisis_models.dart';
import 'package:crisisync/services/websocket_service.dart';

class CrisisProvider extends ChangeNotifier {
  // Configurable Backend API host
  String _backendHost = "127.0.0.1:8000";
  
  WebSocketService? _wsService;
  
  // State variables
  Incident? _activeIncident;
  String? _activeStep;
  List<LogMessage> _logs = [];
  Map<String, dynamic> _mapOverlays = {};
  Map<String, dynamic> _dispatchTicket = {};
  Map<String, dynamic> _publicAlert = {};
  SimulationState? _simulationState;
  List<Incident> _incidentsHistory = [];
  bool _isConnected = false;
  bool _isSimulating = false;

  // Getters
  Incident? get activeIncident => _activeIncident;
  String? get activeStep => _activeStep;
  List<LogMessage> get logs => _logs;
  Map<String, dynamic> get mapOverlays => _mapOverlays;
  Map<String, dynamic> get dispatchTicket => _dispatchTicket;
  Map<String, dynamic> get publicAlert => _publicAlert;
  SimulationState? get simulationState => _simulationState;
  List<Incident> get incidentsHistory => _incidentsHistory;
  bool get isConnected => _isConnected;
  bool get isSimulating => _isSimulating;
  String get backendHost => _backendHost;

  bool get _isSecure => !_backendHost.startsWith("localhost") && 
                        !_backendHost.startsWith("127.0.0.1") && 
                        !_backendHost.startsWith("10.0.2.2");

  String get _httpScheme => _isSecure ? "https://" : "http://";
  String get _wsScheme => _isSecure ? "wss://" : "ws://";

  void updateBackendHost(String host) {
    String cleanHost = host.trim();
    if (cleanHost.startsWith("http://")) cleanHost = cleanHost.substring(7);
    if (cleanHost.startsWith("https://")) cleanHost = cleanHost.substring(8);
    if (cleanHost.startsWith("ws://")) cleanHost = cleanHost.substring(5);
    if (cleanHost.startsWith("wss://")) cleanHost = cleanHost.substring(6);
    if (cleanHost.endsWith("/")) cleanHost = cleanHost.substring(0, cleanHost.length - 1);

    _backendHost = cleanHost;
    _wsService?.disconnect();
    _wsService = null;
    initialize();
    notifyListeners();
  }

  void initialize() {
    final wsUrl = "$_wsScheme$_backendHost/ws/live";
    _wsService = WebSocketService(url: wsUrl);
    
    _wsService!.onConnected = () {
      _isConnected = true;
      notifyListeners();
    };

    _wsService!.onConnectionError = (err) {
      _isConnected = false;
      notifyListeners();
    };

    _wsService!.onMessageReceived = (data) {
      _parseStatePayload(data);
    };

    _wsService!.connect();
    fetchIncidentsHistory();
  }

  void _parseStatePayload(Map<String, dynamic> data) {
    _activeStep = data['step'];
    _isSimulating = _activeStep != null && _activeStep != "outcome_simulation";

    if (data['incident'] != null) {
      _activeIncident = Incident.fromJson(data['incident']);
    } else {
      _activeIncident = null;
    }

    if (data['simulation_state'] != null) {
      _simulationState = SimulationState.fromJson(data['simulation_state']);
    } else {
      _simulationState = null;
    }

    _mapOverlays = data['map_overlays'] ?? {};
    _dispatchTicket = data['dispatch_ticket'] ?? {};
    _publicAlert = data['public_alert'] ?? {};

    if (data['logs'] != null) {
      _logs = (data['logs'] as List)
          .map((e) => LogMessage.fromJson(e))
          .toList();
    }

    // Refresh history if simulation just completed
    if (_activeStep == "outcome_simulation") {
      fetchIncidentsHistory();
    }

    notifyListeners();
  }

  Future<void> fetchIncidentsHistory() async {
    try {
      final response = await http.get(Uri.parse("$_httpScheme$_backendHost/api/incidents"));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        _incidentsHistory = list.map((e) => Incident.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching incident history: $e");
    }
  }

  Future<bool> startSimulation(List<Map<String, dynamic>> signals) async {
    try {
      // Clear current state before starting a new simulation
      clearActive();
      _isSimulating = true;
      notifyListeners();

      // Trigger simulation via REST API (or we can use WebSocket)
      final response = await http.post(
        Uri.parse("$_httpScheme$_backendHost/api/simulate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"signals": signals}),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        _isSimulating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("Error starting simulation: $e");
      _isSimulating = false;
      notifyListeners();
      return false;
    }
  }

  void clearActive() {
    _activeIncident = null;
    _activeStep = null;
    _logs = [];
    _mapOverlays = {};
    _dispatchTicket = {};
    _publicAlert = {};
    _simulationState = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService?.disconnect();
    super.dispose();
  }
}

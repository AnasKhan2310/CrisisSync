class Signal {
  final String id;
  final String source;
  final String content;
  final String timestamp;
  final String? location;

  Signal({
    required this.id,
    required this.source,
    required this.content,
    required this.timestamp,
    this.location,
  });

  factory Signal.fromJson(Map<String, dynamic> json) {
    return Signal(
      id: json['id'] ?? '',
      source: json['source'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] ?? '',
      location: json['location'],
    );
  }
}

class ActionItem {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  String status; // "pending", "in_progress", "completed"

  ActionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.status,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedTo: json['assigned_to'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

class AffectedZone {
  final String name;
  final String severity;
  final List<double>? coordinates; // [lat, lng]

  AffectedZone({
    required this.name,
    required this.severity,
    this.coordinates,
  });

  factory AffectedZone.fromJson(Map<String, dynamic> json) {
    List<double>? coords;
    if (json['coordinates'] != null) {
      coords = List<double>.from(json['coordinates'].map((e) => (e as num).toDouble()));
    }
    return AffectedZone(
      name: json['name'] ?? '',
      severity: json['severity'] ?? 'MEDIUM',
      coordinates: coords,
    );
  }
}

class Incident {
  final String id;
  final String title;
  final String type;
  final String severity;
  final double confidence;
  final String reasoning;
  final String location;
  final String timestamp;
  final List<AffectedZone> affectedZones;
  final List<String> signals;
  final List<ActionItem> actions;
  final String status; // "active", "mitigated", "resolved"

  Incident({
    required this.id,
    required this.title,
    required this.type,
    required this.severity,
    required this.confidence,
    required this.reasoning,
    required this.location,
    required this.timestamp,
    required this.affectedZones,
    required this.signals,
    required this.actions,
    required this.status,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'road_blockage',
      severity: json['severity'] ?? 'MEDIUM',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] ?? '',
      location: json['location'] ?? 'Unknown',
      timestamp: json['timestamp'] ?? '',
      affectedZones: (json['affected_zones'] as List?)
              ?.map((e) => AffectedZone.fromJson(e))
              .toList() ??
          [],
      signals: List<String>.from(json['signals'] ?? []),
      actions: (json['actions'] as List?)
              ?.map((e) => ActionItem.fromJson(e))
              .toList() ??
          [],
      status: json['status'] ?? 'active',
    );
  }
}

class SimulationState {
  final String incidentId;
  final String status;
  final int currentStep;
  final int totalSteps;
  final int beforeCongestion;
  final int afterCongestion;
  final int beforeEta;
  final int afterEta;
  final List<String> logs;

  SimulationState({
    required this.incidentId,
    required this.status,
    required this.currentStep,
    required this.totalSteps,
    required this.beforeCongestion,
    required this.afterCongestion,
    required this.beforeEta,
    required this.afterEta,
    required this.logs,
  });

  factory SimulationState.fromJson(Map<String, dynamic> json) {
    return SimulationState(
      incidentId: json['incident_id'] ?? '',
      status: json['status'] ?? 'idle',
      currentStep: json['current_step'] ?? 0,
      totalSteps: json['total_steps'] ?? 5,
      beforeCongestion: json['before_congestion'] ?? 0,
      afterCongestion: json['after_congestion'] ?? 0,
      beforeEta: json['before_eta'] ?? 0,
      afterEta: json['after_eta'] ?? 0,
      logs: List<String>.from(json['logs'] ?? []),
    );
  }
}

class LogMessage {
  final String timestamp;
  final String level;
  final String? agent;
  final String message;

  LogMessage({
    required this.timestamp,
    required this.level,
    this.agent,
    required this.message,
  });

  factory LogMessage.fromJson(Map<String, dynamic> json) {
    return LogMessage(
      timestamp: json['timestamp'] ?? '',
      level: json['level'] ?? 'INFO',
      agent: json['agent'],
      message: json['message'] ?? '',
    );
  }
}

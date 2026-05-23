from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

class Signal(BaseModel):
    id: str
    source: str  # "social", "weather", "traffic", "emergency_report"
    content: str
    timestamp: datetime = Field(default_factory=datetime.now)
    location: Optional[str] = None  # e.g. "G-10", "George Town", "Saddar"
    metadata: Dict[str, Any] = Field(default_factory=dict)

class ActionItem(BaseModel):
    id: str
    title: str
    description: str
    assigned_to: str  # e.g., "traffic_control", "rescue_1122", "alert_broadcast"
    status: str  # "pending", "in_progress", "completed"
    created_at: datetime = Field(default_factory=datetime.now)

class AffectedZone(BaseModel):
    name: str
    severity: str  # "LOW", "MEDIUM", "HIGH"
    coordinates: Optional[List[float]] = None  # [lat, lng]

class Incident(BaseModel):
    id: str
    title: str
    type: str  # "urban_flooding", "heatwave", "road_blockage", "accident", "infrastructure_failure"
    severity: str  # "LOW", "MEDIUM", "HIGH"
    confidence: float
    reasoning: str
    location: str
    timestamp: datetime = Field(default_factory=datetime.now)
    affected_zones: List[AffectedZone] = Field(default_factory=list)
    signals: List[str] = Field(default_factory=list)  # IDs of source signals
    actions: List[ActionItem] = Field(default_factory=list)
    status: str = "active"  # "active", "mitigated", "resolved"

class SimulationState(BaseModel):
    incident_id: str
    status: str  # "idle", "running", "completed"
    current_step: int
    total_steps: int
    before_congestion: int
    after_congestion: int
    before_eta: int
    after_eta: int
    logs: List[str] = Field(default_factory=list)

class LogMessage(BaseModel):
    timestamp: str
    level: str  # "INFO", "WARNING", "ERROR", "AGENT"
    agent: Optional[str] = None  # Name of agent generating the log
    message: str

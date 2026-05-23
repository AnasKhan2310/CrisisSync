from typing import List, Dict, Any
from app.agents.base import BaseAgent
from app.models import Incident

class RouteOptimizationAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Route Optimization Agent",
            description="Analyzes traffic anomalies and calculates optimized detours and alternate pathways."
        )

    async def execute(self, state: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        incident: Incident = state.get("incident")
        logs: List[Any] = state.get("logs", [])

        if not incident:
            return state

        # Check if traffic_control actions are pending
        traffic_actions = [a for a in incident.actions if a.assigned_to == "traffic_control"]
        if not traffic_actions:
            logs.append(self.log("No traffic rerouting required for this incident type.", level="INFO"))
            return state

        logs.append(self.log(f"Calculating alternative pathways for affected zone: {incident.location}"))
        
        # Simulating rerouting calculations
        blocked_roads = []
        alternate_routes = []

        if "g-10" in incident.location.lower():
            blocked_roads = ["G-10 Markaz Outer Ring Road", "Sector G-10/4 Double Road"]
            alternate_routes = ["Ibn-e-Sina Road (Reroute via G-9)", "Sector G-11 Main Boulevard"]
        elif "saddar" in incident.location.lower():
            blocked_roads = ["Murree Road Flyover Underpass", "Saddar Metro Plaza Chowk"]
            alternate_routes = ["Mall Road Bypass", "Peshawar Road link"]
        elif "george town" in incident.location.lower():
            blocked_roads = ["George Town Central Link Road", "George Town Underpass"]
            alternate_routes = ["River Road Bypass", "East Highway Arterial"]
        else:
            blocked_roads = ["Main Intersection Boulevard"]
            alternate_routes = ["Service Road East detour"]

        # Save to state
        state["map_overlays"] = {
            "blocked_roads": blocked_roads,
            "alternate_routes": alternate_routes,
            "flood_zones": [incident.location] if incident.type == "urban_flooding" else []
        }

        logs.append(self.log(f"Rerouting computed successfully."))
        logs.append(self.log(f"Closed Roads: {', '.join(blocked_roads)}", level="WARNING"))
        logs.append(self.log(f"Assigned Detours: {', '.join(alternate_routes)}", level="INFO"))

        # Transition action status
        for action in traffic_actions:
            action.status = "in_progress"

        return state

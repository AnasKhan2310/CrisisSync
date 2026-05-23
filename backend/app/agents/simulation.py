from typing import List, Dict, Any
from app.agents.base import BaseAgent
from app.models import Incident, SimulationState

class SimulationAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Simulation Agent",
            description="Executes simulations, resolves incident stages, and measures response outcomes."
        )

    async def execute(self, state: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        incident: Incident = state.get("incident")
        logs: List[Any] = state.get("logs", [])

        if not incident:
            return state

        logs.append(self.log("Initializing response outcome simulation engine."))

        # Calculate metrics before vs after response
        before_congestion = 92 if incident.severity == "HIGH" else 65
        after_congestion = 48 if incident.severity == "HIGH" else 30
        
        before_eta = 26 if incident.severity == "HIGH" else 18
        after_eta = 12 if incident.severity == "HIGH" else 9

        # Simulate steps
        simulation_logs = [
            f"[Step 1] Commencing traffic diversion to alternate routes.",
            f"[Step 2] Emergency dispatch arrival at {incident.location}.",
            f"[Step 3] Water suction and clearing pumps online." if incident.type == "urban_flooding" else f"[Step 3] Securing and sanitizing hazard zone.",
            f"[Step 4] Restoring main artery roadway flow.",
            f"[Step 5] Metropolitan congestion levels normalized."
        ]

        # Save Simulation State to state
        sim_state = SimulationState(
            incident_id=incident.id,
            status="completed",
            current_step=5,
            total_steps=5,
            before_congestion=before_congestion,
            after_congestion=after_congestion,
            before_eta=before_eta,
            after_eta=after_eta,
            logs=simulation_logs
        )

        state["simulation_state"] = sim_state

        # Mark all incident actions as completed
        for action in incident.actions:
            action.status = "completed"

        # Resolve incident
        incident.status = "mitigated"

        logs.append(self.log("Simulation complete. Outflow statistics calculated."))
        logs.append(self.log(f"Traffic Congestion: {before_congestion}% -> {after_congestion}% (-{before_congestion - after_congestion}%)", level="INFO"))
        logs.append(self.log(f"Emergency ETA: {before_eta} mins -> {after_eta} mins (-{before_eta - after_eta} mins)", level="INFO"))
        logs.append(self.log(f"Incident {incident.id} state updated to: MITIGATED"))

        return state

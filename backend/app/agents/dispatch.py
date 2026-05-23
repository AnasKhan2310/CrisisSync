from typing import List, Dict, Any
from app.agents.base import BaseAgent
from app.models import Incident

class EmergencyDispatchAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Emergency Dispatch Agent",
            description="Coordinates emergency responses, dispatches field units, and opens incident tickets."
        )

    async def execute(self, state: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        incident: Incident = state.get("incident")
        logs: List[Any] = state.get("logs", [])

        if not incident:
            return state

        # Check if rescue actions are pending
        rescue_actions = [a for a in incident.actions if a.assigned_to == "rescue_1122"]
        if not rescue_actions:
            logs.append(self.log("No emergency crew dispatch required for this incident type.", level="INFO"))
            return state

        logs.append(self.log(f"Initiating emergency crew mobilization for: {incident.location}"))

        # Generate mock dispatch units
        dispatch_units = []
        if incident.type == "urban_flooding":
            dispatch_units = ["Rescue 1122 Water Rescue Unit 3", "Municipal De-watering Team B"]
        elif incident.type == "heatwave":
            dispatch_units = ["Red Crescent Mobile Hydration Unit 1", "Civil Defense Medical Team"]
        elif incident.type == "accident":
            dispatch_units = ["Rescue 1122 Ambulance 12", "Metropolitan Tow Truck Service"]
        else:
            dispatch_units = ["Municipal Emergency Response Unit 1"]

        # Generate ticket metadata
        ticket_id = f"tkt_{incident.id[4:]}"
        
        state["dispatch_ticket"] = {
            "ticket_id": ticket_id,
            "units": dispatch_units,
            "status": "dispatched",
            "priority": "CRITICAL" if incident.severity == "HIGH" else "HIGH"
        }

        logs.append(self.log(f"Emergency Dispatch Ticket Created: {ticket_id} | Status: DISPATCHED"))
        for unit in dispatch_units:
            logs.append(self.log(f"Unit Mobilized: '{unit}' - ETA 12 mins.", level="INFO"))

        # Transition action status
        for action in rescue_actions:
            action.status = "in_progress"

        return state

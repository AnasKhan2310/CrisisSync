from typing import List, Dict, Any
from app.agents.base import BaseAgent
from app.models import Incident

class AlertBroadcastingAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Alert Broadcasting Agent",
            description="Broadcasts push notifications, evacuation warnings, and public safety announcements."
        )

    async def execute(self, state: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        incident: Incident = state.get("incident")
        logs: List[Any] = state.get("logs", [])

        if not incident:
            return state

        # Check if alert actions are pending
        alert_actions = [a for a in incident.actions if a.assigned_to == "alert_broadcast"]
        if not alert_actions:
            logs.append(self.log("No public alerts scheduled.", level="INFO"))
            return state

        logs.append(self.log(f"Preparing alert broadcast for zones near {incident.location}"))

        # Generate broadcast message
        alert_title = "CRITICAL ALERT" if incident.severity == "HIGH" else "SAFETY ADVISORY"
        alert_message = ""

        if incident.type == "urban_flooding":
            alert_message = f"Flash floods reported at {incident.location}. Avoid low-lying areas. Traffic rerouted."
        elif incident.type == "heatwave":
            alert_message = f"Extreme temperature warning for {incident.location}. Stay hydrated. Avoid direct sun exposure."
        elif incident.type == "accident":
            alert_message = f"Severe collision at {incident.location}. Expect heavy traffic. Use alternate routes."
        else:
            alert_message = f"Emergency situation reported at {incident.location}. Exercise caution."

        broadcast_channel = "SMS & Mobile Push Notification Grid"

        state["public_alert"] = {
            "title": alert_title,
            "message": alert_message,
            "channel": broadcast_channel,
            "timestamp": incident.timestamp.strftime("%Y-%m-%d %H:%M:%S")
        }

        logs.append(self.log(f"Broadcasting Alert: [{alert_title}] {alert_message}"))
        logs.append(self.log(f"Alert transmitted to cellular grid via {broadcast_channel}.", level="INFO"))

        # Transition action status
        for action in alert_actions:
            action.status = "in_progress"

        return state

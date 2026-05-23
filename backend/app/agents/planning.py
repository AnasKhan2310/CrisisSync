from typing import List, Dict, Any
from app.agents.base import BaseAgent
from app.models import Incident, ActionItem
from app.utils.gemini import gemini_client
from datetime import datetime

class PlanningAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Planning Agent",
            description="Formulates action strategies, resource allocations, and response workflows."
        )

    async def execute(self, state: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        incident: Incident = state.get("incident")
        impacts: List[str] = state.get("impacts", [])
        logs: List[Any] = state.get("logs", [])

        if not incident:
            logs.append(self.log("No active incident to formulate actions for.", level="WARNING"))
            return state

        logs.append(self.log(f"Formulating response strategy for: {incident.title}"))

        prompt = f"""
        Incident Title: {incident.title}
        Type: {incident.type}
        Severity: {incident.severity}
        Location: {incident.location}
        Impacts Identified: {', '.join(impacts)}

        Formulate 2-3 specific, actionable response items.
        For each response item, specify:
        - "title": Action name (e.g. "Reroute G-10 traffic")
        - "description": Instructions for execution
        - "assigned_to": One of "traffic_control", "rescue_1122", "alert_broadcast"

        Return a JSON structure:
        {{
            "actions": [
                {{
                    "title": "Action Title",
                    "description": "Action Description",
                    "assigned_to": "traffic_control/rescue_1122/alert_broadcast"
                }}
            ]
        }}
        """

        system_instruction = "You are a disaster response planner. Recommend emergency response workflows and resource assignments in JSON."
        result = await gemini_client.generate_json(prompt, system_instruction)

        actions = []
        if result and "actions" in result:
            for idx, act in enumerate(result["actions"]):
                actions.append(ActionItem(
                    id=f"act_{int(datetime.now().timestamp())}_{idx}",
                    title=act.get("title", "Coordinated Action"),
                    description=act.get("description", "Deploy rescue/mitigation teams."),
                    assigned_to=act.get("assigned_to", "rescue_1122"),
                    status="pending"
                ))
            
            incident.actions = actions
            logs.append(self.log(f"Formulated {len(actions)} coordinated action items."))
            for a in actions:
                logs.append(self.log(f"Action '{a.title}' assigned to {a.assigned_to.upper()}.", level="INFO"))
        else:
            logs.append(self.log("Failed to generate custom actions. Using emergency safety defaults.", level="WARNING"))
            # Fallback action
            fallback_act = ActionItem(
                id=f"act_{int(datetime.now().timestamp())}_0",
                title="Establish Perimeter",
                description="Secure and block entrance to the affected sector.",
                assigned_to="traffic_control",
                status="pending"
            )
            incident.actions = [fallback_act]
            logs.append(self.log(f"Action '{fallback_act.title}' assigned to {fallback_act.assigned_to.upper()}.", level="INFO"))

        return state

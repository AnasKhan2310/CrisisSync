import asyncio
from typing import List, Dict, Any, Callable
from app.agents.intake import SignalIntakeAgent
from app.agents.detection import CrisisDetectionAgent
from app.agents.severity import SeverityAnalysisAgent
from app.agents.planning import PlanningAgent
from app.agents.routing import RouteOptimizationAgent
from app.agents.dispatch import EmergencyDispatchAgent
from app.agents.alerts import AlertBroadcastingAgent
from app.agents.simulation import SimulationAgent
from app.models import LogMessage

class CrisisOrchestrator:
    def __init__(self, broadcast_callback: Callable[[Dict[str, Any]], Any] = None):
        # Callback to broadcast updates via WebSockets or Firebase
        self.broadcast_callback = broadcast_callback
        
        # Instantiate agents
        self.intake_agent = SignalIntakeAgent()
        self.detection_agent = CrisisDetectionAgent()
        self.severity_agent = SeverityAnalysisAgent()
        self.planning_agent = PlanningAgent()
        self.routing_agent = RouteOptimizationAgent()
        self.dispatch_agent = EmergencyDispatchAgent()
        self.alerts_agent = AlertBroadcastingAgent()
        self.simulation_agent = SimulationAgent()

    async def run_orchestration(self, raw_signals: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Runs the full multi-agent orchestration pipeline.
        Pushes updates to the callback at each step with simulated delays.
        """
        state = {
            "signals": [],
            "incident": None,
            "impacts": [],
            "map_overlays": {},
            "dispatch_ticket": {},
            "public_alert": {},
            "simulation_state": None,
            "logs": []
        }

        # Step 1: Signal Intake
        state = await self.intake_agent.execute(state, raw_signals=raw_signals)
        await self._broadcast_step(state, "signal_intake")
        await asyncio.sleep(1.5)

        # Step 2: Crisis Detection
        state = await self.detection_agent.execute(state)
        if not state.get("incident"):
            return state
        await self._broadcast_step(state, "crisis_detection")
        await asyncio.sleep(1.5)

        # Step 3: Severity Analysis
        state = await self.severity_agent.execute(state)
        await self._broadcast_step(state, "severity_analysis")
        await asyncio.sleep(1.5)

        # Step 4: Response Planning
        state = await self.planning_agent.execute(state)
        await self._broadcast_step(state, "response_planning")
        await asyncio.sleep(1.5)

        # Step 5: Route Optimization
        state = await self.routing_agent.execute(state)
        await self._broadcast_step(state, "route_optimization")
        await asyncio.sleep(1.5)

        # Step 6: Emergency Dispatch
        state = await self.dispatch_agent.execute(state)
        await self._broadcast_step(state, "emergency_dispatch")
        await asyncio.sleep(1.5)

        # Step 7: Alert Broadcasting
        state = await self.alerts_agent.execute(state)
        await self._broadcast_step(state, "alert_broadcasting")
        await asyncio.sleep(1.5)

        # Step 8: Outcome Simulation
        state = await self.simulation_agent.execute(state)
        await self._broadcast_step(state, "outcome_simulation")
        
        return state

    async def _broadcast_step(self, state: Dict[str, Any], step_name: str):
        if not self.broadcast_callback:
            return
            
        # Serialize the state to dictionary format for WebSocket transmission
        incident_data = None
        if state["incident"]:
            incident = state["incident"]
            incident_data = {
                "id": incident.id,
                "title": incident.title,
                "type": incident.type,
                "severity": incident.severity,
                "confidence": incident.confidence,
                "reasoning": incident.reasoning,
                "location": incident.location,
                "timestamp": incident.timestamp.strftime("%Y-%m-%d %H:%M:%S"),
                "status": incident.status,
                "affected_zones": [
                    {
                        "name": z.name,
                        "severity": z.severity,
                        "coordinates": z.coordinates
                    } for z in incident.affected_zones
                ],
                "actions": [
                    {
                        "id": a.id,
                        "title": a.title,
                        "description": a.description,
                        "assigned_to": a.assigned_to,
                        "status": a.status
                    } for a in incident.actions
                ]
            }

        sim_state_data = None
        if state["simulation_state"]:
            sim = state["simulation_state"]
            sim_state_data = {
                "incident_id": sim.incident_id,
                "status": sim.status,
                "current_step": sim.current_step,
                "total_steps": sim.total_steps,
                "before_congestion": sim.before_congestion,
                "after_congestion": sim.after_congestion,
                "before_eta": sim.before_eta,
                "after_eta": sim.after_eta,
                "logs": sim.logs
            }

        payload = {
            "step": step_name,
            "incident": incident_data,
            "map_overlays": state["map_overlays"],
            "dispatch_ticket": state["dispatch_ticket"],
            "public_alert": state["public_alert"],
            "simulation_state": sim_state_data,
            "logs": [
                {
                    "timestamp": l.timestamp,
                    "level": l.level,
                    "agent": l.agent,
                    "message": l.message
                } for l in state["logs"]
            ]
        }

        # Fire callback
        await self.broadcast_callback(payload)

from typing import List, Dict, Any
from app.agents.base import BaseAgent
from app.models import Incident
from app.utils.gemini import gemini_client

class SeverityAnalysisAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Severity Analysis Agent",
            description="Estimates severity, calculates confidence scores, and determines critical impacts."
        )

    async def execute(self, state: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        incident: Incident = state.get("incident")
        signals = state.get("signals", [])
        logs: List[Any] = state.get("logs", [])

        if not incident:
            logs.append(self.log("No active incident to grade.", level="WARNING"))
            return state

        logs.append(self.log(f"Evaluating severity and impact metrics for incident: {incident.title}"))

        # We can analyze severity based on sources, keywords, and density of signals
        weather_alert_present = any(s.source == "weather" for s in signals)
        congestion_reports = len([s for s in signals if s.source == "traffic"])
        total_signals = len(signals)

        # Build prompt for severity calculation
        prompt = f"""
        Incident Title: {incident.title}
        Incident Type: {incident.type}
        Location: {incident.location}
        Total Signals Ingested: {total_signals}
        Weather Alert Present: {weather_alert_present}
        Traffic Congestion Reports: {congestion_reports}

        Estimate the severity level ("LOW", "MEDIUM", "HIGH") and calculate a confidence score (between 0.0 and 1.0) based on signal volume, source credibility, and weather warnings.
        List specific impacts (e.g. "Traffic blocked", "Stranded vehicles", "Emergency delay risks").

        Return a JSON structure:
        {{
            "severity": "LOW/MEDIUM/HIGH",
            "confidence": 0.85,
            "impacts": ["Impact 1", "Impact 2"]
        }}
        """
        
        system_instruction = "You are a crisis risk assessor. Determine emergency severity and list impacts in a structured JSON response."
        result = await gemini_client.generate_json(prompt, system_instruction)

        if result:
            severity = result.get("severity", "MEDIUM")
            confidence = result.get("confidence", 0.85)
            impacts = result.get("impacts", ["Traffic disruption", "Emergency access delay"])
            
            # Update incident in state
            incident.severity = severity
            incident.confidence = confidence
            
            # Save impacts to state for the planning agent
            state["impacts"] = impacts
            
            logs.append(self.log(f"Severity analysis complete. Severity: {severity} | Confidence: {confidence:.2f}"))
            logs.append(self.log(f"Key Impacts: {', '.join(impacts)}", level="INFO"))
        else:
            logs.append(self.log("Failed to parse severity metrics. Applying defaults (MEDIUM, 0.70).", level="WARNING"))
            incident.severity = "MEDIUM"
            incident.confidence = 0.70
            state["impacts"] = ["Traffic disruption"]

        return state

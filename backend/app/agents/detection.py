from typing import List, Dict, Any
from app.agents.base import BaseAgent
from app.models import Signal, Incident, AffectedZone
from app.utils.gemini import gemini_client
import json

class CrisisDetectionAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Crisis Detection Agent",
            description="Classifies anomalies and clusters reports into single incident events."
        )

    async def execute(self, state: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        signals: List[Signal] = state.get("signals", [])
        logs: List[Any] = state.get("logs", [])

        if not signals:
            logs.append(self.log("No signals available to analyze.", level="WARNING"))
            return state

        logs.append(self.log(f"Analyzing {len(signals)} normalized signals to identify incident clusters."))

        # Build a prompt containing all active signals
        signals_text = ""
        for s in signals:
            signals_text += f"- [{s.source}] (Location: {s.location or 'N/A'}): '{s.content}'\n"

        prompt = f"""
        Analyze the following real-time signals from social media, weather feeds, and traffic maps:
        {signals_text}

        Determine if there is a primary crisis situation. Group all relevant signals together under this crisis.
        Classify the crisis into one of the following types:
        - "urban_flooding"
        - "heatwave"
        - "road_blockage"
        - "accident"
        - "infrastructure_failure"

        Return a JSON structure matching this format exactly:
        {{
            "title": "A short descriptive title for the incident",
            "type": "crisis_type",
            "reasoning": "Detailed justification explaining why this crisis was detected and how the signals cluster together",
            "location": "The main sector/location of the incident",
            "affected_zones": [
                {{
                    "name": "Sub-area or road affected",
                    "severity": "LOW/MEDIUM/HIGH"
                }}
            ]
        }}
        """

        system_instruction = "You are an expert AI emergency coordinator. Group noisy signals and identify the root metropolitan emergency in JSON."

        # Call Gemini (or heuristic engine fallback)
        result = await gemini_client.generate_json(prompt, system_instruction)
        
        if result:
            # Create an Incident
            incident_id = f"inc_{int(signals[0].timestamp.timestamp())}"
            
            # Map zones
            affected_zones = []
            for zone_data in result.get("affected_zones", []):
                affected_zones.append(AffectedZone(
                    name=zone_data.get("name", "Unknown Zone"),
                    severity=zone_data.get("severity", "MEDIUM")
                ))

            # Coordinates for mock map displaying based on locations
            self._assign_mock_coordinates(result.get("location", ""), affected_zones)

            incident = Incident(
                id=incident_id,
                title=result.get("title", "Detected Incident"),
                type=result.get("type", "road_blockage"),
                severity="MEDIUM",  # Will be refined by Severity Analysis Agent
                confidence=0.9,     # Will be refined
                reasoning=result.get("reasoning", ""),
                location=result.get("location", "Metropolitan Area"),
                affected_zones=affected_zones,
                signals=[s.id for s in signals],
                actions=[],
                status="active"
            )

            state["incident"] = incident
            logs.append(self.log(
                f"Incident Detected: '{incident.title}' | Type: {incident.type.upper()} | Primary Location: {incident.location}"
            ))
            logs.append(self.log(f"Detection Reasoning: {incident.reasoning}", level="INFO"))
        else:
            logs.append(self.log("Failed to detect any incident from incoming signals.", level="ERROR"))

        return state

    def _assign_mock_coordinates(self, location: str, zones: List[AffectedZone]):
        """Assigns coordinates based on Islamabad-style metropolitan areas for map rendering."""
        loc_lower = location.lower()
        
        # Base coordinates
        # Islamabad center coordinates: 33.6844, 73.0479
        base_coords = [33.6844, 73.0479]  # Default
        
        if "g-10" in loc_lower:
            base_coords = [33.6823, 73.0135]
        elif "saddar" in loc_lower:
            base_coords = [33.5973, 73.0479]
        elif "george town" in loc_lower: # Simulating George Town / G-Town
            base_coords = [33.7294, 73.0931]
        elif "kashmir highway" in loc_lower or "highway" in loc_lower:
            base_coords = [33.6644, 73.0031]

        # Offset each zone coordinates slightly
        import random
        for i, zone in enumerate(zones):
            offset_lat = (i + 1) * 0.005 * (-1 if i % 2 == 0 else 1)
            offset_lng = (i + 1) * 0.005 * (1 if i % 2 == 0 else -1)
            zone.coordinates = [base_coords[0] + offset_lat, base_coords[1] + offset_lng]

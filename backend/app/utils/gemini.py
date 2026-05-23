import json
import os
import re
from typing import Optional, Dict, Any, List
from app.config import settings

# Attempt to configure google-generativeai
try:
    import google.generativeai as genai
    HAS_GENAI = True
    if settings.gemini_api_key:
        genai.configure(api_key=settings.gemini_api_key)
except ImportError:
    HAS_GENAI = False

class GeminiClient:
    def __init__(self):
        self.api_key_configured = bool(settings.gemini_api_key)
        self.model_name = "gemini-1.5-flash"

    async def generate_json(self, prompt: str, system_instruction: str = "") -> Optional[Dict[str, Any]]:
        """
        Generates content from Gemini, expecting a JSON response.
        If no API key is provided, falls back to local heuristic reasoning.
        """
        if self.api_key_configured and HAS_GENAI:
            try:
                model = genai.GenerativeModel(
                    model_name=self.model_name,
                    generation_config={"response_mime_type": "application/json"},
                    system_instruction=system_instruction
                )
                response = model.generate_content(prompt)
                return json.loads(response.text)
            except Exception as e:
                print(f"Gemini API call failed: {e}. Falling back to heuristic engine.")
        
        # Heuristic Fallback
        return self._heuristic_reasoning(prompt, system_instruction)

    def _heuristic_reasoning(self, prompt: str, system_instruction: str) -> Dict[str, Any]:
        """
        High-fidelity heuristic fallback that matches Roman Urdu and English.
        Mimics what Gemini would return based on prompt context.
        """
        prompt_lower = prompt.lower()
        
        # 1. Determine Crisis Type
        crisis_type = "road_blockage"
        title = "Metropolitan Traffic Interruption"
        severity = "MEDIUM"
        confidence = 0.85
        reasoning = "Signal reports points of traffic blockage on standard arterial roads."
        location = "George Town"
        affected_zones = ["George Town Center"]
        
        # Roman Urdu & English Flood Detection
        if any(w in prompt_lower for w in ["flood", "pani", "barish", "rain", "rainy", "storm", "waterlogging", "dub gaya"]):
            crisis_type = "urban_flooding"
            title = "Urban Flooding and Waterlogging"
            severity = "HIGH"
            confidence = 0.95
            reasoning = "Multiple reports of water logging, heavy rain, and stranded vehicles indicate a flash flood scenario."
            if "g-10" in prompt_lower:
                location = "G-10 Sector"
                affected_zones = ["G-10 Markaz", "G-10/4 Main Boulevard"]
            elif "saddar" in prompt_lower:
                location = "Saddar Area"
                affected_zones = ["Saddar Metro Station", "Main Saddar Road"]
            elif "george town" in prompt_lower:
                location = "George Town"
                affected_zones = ["George Town Central", "George Town Underpass"]
            else:
                location = "Downtown Metropolitan"
                affected_zones = ["Main Arterial Routes"]
                
        # Heatwave Detection
        elif any(w in prompt_lower for w in ["heatwave", "garmi", "hot", "sunstroke", "temperature", "luh", "loo"]):
            crisis_type = "heatwave"
            title = "Severe Heatwave Warning"
            severity = "HIGH"
            confidence = 0.90
            reasoning = "Extreme temperature reports coupled with weather warnings indicate active heatwave risk."
            location = "Metropolitan Area"
            affected_zones = ["Saddar Commercial Hub", "Rawalpindi Center"]
            
        # Accident Detection
        elif any(w in prompt_lower for w in ["accident", "collided", "hathsa", "takkar", "crash", "collision"]):
            crisis_type = "accident"
            title = "Multi-vehicle Collision"
            severity = "MEDIUM"
            confidence = 0.88
            reasoning = "Reports of vehicle collision leading to road obstruction and physical damage."
            location = "Kashmir Highway"
            affected_zones = ["Kashmir Highway Intersection"]
            if "saddar" in prompt_lower:
                location = "Saddar Metro Chowk"
                affected_zones = ["Saddar Commercial Boulevard"]

        # 2. Extract specific entities if possible
        loc_match = re.search(r'(g-10|george town|saddar|kashmir highway|i-9)', prompt_lower)
        if loc_match:
            location = loc_match.group(1).upper()
            
        # Generate Actions based on Crisis Type
        actions = []
        if crisis_type == "urban_flooding":
            actions = [
                {
                    "title": "Reroute Traffic",
                    "description": f"Divert vehicle traffic away from flooded routes at {location}.",
                    "assigned_to": "traffic_control"
                },
                {
                    "title": "Dispatch Drainage & Rescue Team",
                    "description": f"Send emergency pumps and Rescue 1122 vehicles to clear water logged areas at {location}.",
                    "assigned_to": "rescue_1122"
                },
                {
                    "title": "Send Flash Flood Public Alerts",
                    "description": f"Broadcast push notification and SMS to residents warning them to avoid {location}.",
                    "assigned_to": "alert_broadcast"
                }
            ]
        elif crisis_type == "heatwave":
            actions = [
                {
                    "title": "Setup Hydration Camps",
                    "description": "Establish immediate drinking water and cooling stations at commercial sectors.",
                    "assigned_to": "rescue_1122"
                },
                {
                    "title": "Heat Warning Broadcast",
                    "description": "Send extreme heat alerts advising citizens to stay indoors between 11 AM and 4 PM.",
                    "assigned_to": "alert_broadcast"
                }
            ]
        elif crisis_type == "accident":
            actions = [
                {
                    "title": "Dispatch Ambulances",
                    "description": "Send first aid and medical support teams to clear casualties.",
                    "assigned_to": "rescue_1122"
                },
                {
                    "title": "Clear Roadway Obstruction",
                    "description": f"Dispatch tow trucks and traffic wardens to restore flow at {location}.",
                    "assigned_to": "traffic_control"
                }
            ]
        else:
            actions = [
                {
                    "title": "Traffic Wardens Dispatch",
                    "description": f"Send traffic wardens to manually direct traffic flow at {location}.",
                    "assigned_to": "traffic_control"
                }
            ]

        # Structure response output mapping to detection or planning agent formats
        return {
            "title": title,
            "type": crisis_type,
            "severity": severity,
            "confidence": confidence,
            "reasoning": reasoning,
            "location": location,
            "affected_zones": [{"name": z, "severity": severity, "coordinates": None} for z in affected_zones],
            "actions": actions
        }

gemini_client = GeminiClient()

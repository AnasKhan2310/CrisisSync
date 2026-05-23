from typing import List, Dict, Any
from app.agents.base import BaseAgent
from app.models import Signal
import re
from datetime import datetime

class SignalIntakeAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Signal Intake Agent",
            description="Collects, normalizes, and filters incoming multi-source signals."
        )

    async def execute(self, state: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        raw_signals: List[Dict[str, Any]] = kwargs.get("raw_signals", [])
        logs: List[Any] = state.setdefault("logs", [])
        
        logs.append(self.log(f"Starting signal intake for {len(raw_signals)} raw signals."))
        
        normalized_signals: List[Signal] = []
        seen_contents = set()
        
        for raw in raw_signals:
            # Basic deduplication
            content = raw.get("content", "").strip()
            if not content:
                continue
                
            content_cleaned = re.sub(r'\s+', ' ', content.lower())
            if content_cleaned in seen_contents:
                logs.append(self.log(f"Filtered duplicate signal: '{content[:30]}...'", level="INFO"))
                continue
            seen_contents.add(content_cleaned)
            
            # Simple entity extraction for location
            location = self._extract_location(content)
            
            signal_id = f"sig_{int(datetime.now().timestamp())}_{len(normalized_signals)}"
            signal = Signal(
                id=signal_id,
                source=raw.get("source", "social"),
                content=content,
                location=location,
                metadata=raw.get("metadata", {})
            )
            normalized_signals.append(signal)
            logs.append(self.log(f"Normalized signal {signal.id} from source: {signal.source}. Location: {location or 'Unknown'}"))

        state["signals"] = normalized_signals
        logs.append(self.log(f"Signal intake complete. Ingested {len(normalized_signals)} unique signals."))
        return state

    def _extract_location(self, content: str) -> Optional[str]:
        # Identify common locations in metropolitan simulation (Saddar, G-10, George Town, Kashmir Highway, F-6, etc.)
        content_lower = content.lower()
        locations = ["g-10", "george town", "saddar", "kashmir highway", "f-6", "i-9", "blue area", "highway"]
        for loc in locations:
            if loc in content_lower:
                return loc.upper()
        return None

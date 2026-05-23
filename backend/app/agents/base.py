from typing import List, Dict, Any, Optional
from datetime import datetime
from app.models import LogMessage

class BaseAgent:
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description

    def log(self, message: str, level: str = "AGENT") -> LogMessage:
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] [{self.name}] {message}")
        return LogMessage(
            timestamp=timestamp,
            level=level,
            agent=self.name,
            message=message
        )

    async def execute(self, state: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        """
        Execute the agent's logic on the current state.
        Must be overridden by subclasses.
        Returns the updated state and optionally updates the log.
        """
        raise NotImplementedError("Agents must implement the execute method")

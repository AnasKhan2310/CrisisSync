import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    # Gemini API settings
    gemini_api_key: Optional[str] = None
    
    # Firebase configuration
    firebase_credentials_path: Optional[str] = None
    firebase_database_url: Optional[str] = None
    
    # Server configuration
    host: str = "0.0.0.0"
    port: int = 8000
    
    # OpenWeather & Traffic APIs (Simulated if empty)
    openweather_api_key: Optional[str] = None
    google_maps_api_key: Optional[str] = None

settings = Settings()

# CrisisSync
> AI-Powered Urban Crisis Coordination Platform

CrisisSync is an intelligent disaster operations command center prototype designed to ingest metropolitan alerts, detect emergencies, and plan and simulate real-time response actions.

---

## Architecture Overview

CrisisSync leverages a **multi-agent reasoning system** in the backend and a **realtime telemetry cockpit** on the mobile frontend.

```mermaid
graph TD
    %% Intake Layer
    Signals[Social Media / Weather Feeds / Traffic Sensors] --> Ingest[Signal Intake Agent]
    
    %% Multi-Agent Analysis Pipeline
    subgraph AI Agents Pipeline
        Ingest --> Detect[Crisis Detection Agent]
        Detect --> Severity[Severity Analysis Agent]
        Severity --> Planner[Planning Agent]
    end

    %% Allocation Layer
    Planner --> Routing[Route Optimization Agent]
    Planner --> Dispatch[Emergency Dispatch Agent]
    Planner --> Alerts[Alert Broadcasting Agent]

    %% Simulation & Outcome Layer
    Routing & Dispatch & Alerts --> Simulation[Simulation Agent]
    
    %% Synchronization Layer
    Simulation --> WebSockets[WebSocket Server]
    Simulation --> Firebase[Firebase Realtime Database]
    
    %% Frontend Sync
    WebSockets & Firebase --> Flutter[Flutter Mobile App]
```

### Components

1. **Flutter Mobile Application (`mobile_app/`)**:
   - **Splash Screen**: Pulsing loading radar animation.
   - **Live Crisis Dashboard**: Dynamic telemetry gauges (Threat index, Traffic flow, Weather status) and scrolling real-time Agent log console.
   - **Incident Details Screen**: Deep-dive AI reasoning justification, affected zones layout, resource tasks, and simulated before-vs-after outcome charts.
   - **Live Map Screen**: Custom vector painter mapping active locations, closed arteries (red), detours (green dashes), and ambulance coordinates.
   - **Alert Center**:Evacuation SMS broadcasts and emergency public safety bulletins.
   - **Admin Simulation Panel**: Ingestion controls to trigger preset events (Rainfall, Road accidents, Heatwaves).

2. **FastAPI Backend (`backend/`)**:
   - **Modular Agent Architecture**: Individual Python class modules for each orchestrator agent.
   - **Gemini API Integration**: Uses Gemini to analyze Rome-Urdu and noisy social inputs, with automatic structural heuristics fallback.
   - **WebSocket Sync Server**: Streams logs and status updates step-by-step with small delays (1.5s) to allow users to watch the agent reasoning pipeline evolve.
   - **Firebase Realtime Sync**: Integrates with Firebase DB if coordinates are configured in `.env`.

---

## Setup & Execution

### 1. Prerequisites
- **Python 3.10+**
- **Flutter 3.0+**
- (Optional) **Gemini API Key** 

### 2. Backend Setup
1. Open a terminal, navigate to the `backend/` directory:
   ```bash
   cd backend
   ```
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   # Windows
   .\venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Verify environment configuration:
   Open the `.env` file and verify your keys:
   ```env
   GEMINI_API_KEY="your-api-key-here"
   ```
5. Run the FastAPI development server:
   ```bash
   uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
   ```
   The interactive API docs will be available at `http://127.0.0.1:8000/docs`.

### 3. Mobile App Setup
1. Open a terminal and navigate to the `mobile_app/` directory:
   ```bash
   cd mobile_app
   ```
2. Install packages:
   ```bash
   flutter pub get
   ```
3. Run the app on your preferred target device:
   ```bash
   flutter run
   ```
   *Note: If running on an Android Emulator, select the settings cog in the top-right of the Flutter app and update the backend host to `10.0.2.2:8000` to route correctly to the local machine.*

### 4. Cloud Deployment (Render.com)
The backend can be deployed 24/7 in the cloud on Render.com:
1. Log in to [Render.com](https://render.com) and create a new **Web Service**.
2. Connect your GitHub repository `AnasKhan2310/CrisisSync`.
3. Set the following settings:
   - **Root Directory**: `backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
4. Add these Environment Variables under the service's **Environment** tab:
   - `GEMINI_API_KEY`: The Gemini API Key (e.g., `AIzaSyDdQvMkIVX0eOV267GCnbh33prVvm23nBk`)
   - `FIREBASE_DATABASE_URL`: The Firebase Realtime Database URL (e.g., `https://crisissync-90c4b-default-rtdb.firebaseio.com/`)
   - `FIREBASE_CREDENTIALS_JSON`: The raw string contents of `firebase_key.json`
5. Deploy the web service. Render will provide a secure HTTPS/WSS URL (e.g. `https://crisissync-backend.onrender.com`).
6. Open the settings dialog in the Flutter app and enter your new Render domain name to connect remotely!

---

## Core Agents

- **Signal Intake Agent**: Cleans and normalizes Roman Urdu (e.g. *"G-10 mein pani bhar gaya hai"*) and weather alerts, filtering duplicate entries.
- **Crisis Detection Agent**: Group signals and determines the primary emergency situation using NLP classifications.
- **Severity Analysis Agent**: Refines risk severity (LOW, MEDIUM, HIGH) and maps geographical impacts.
- **Planning Agent**: Outlines resource allocations and tasks assigned to traffic units, Rescue 1122, or broadcast cells.
- **Route Optimization Agent**: Redirects traffic patterns around hazard areas, calculating detour paths.
- **Emergency Dispatch Agent**: Opens field tickets and dispatches response vehicles.
- **Alert Broadcasting Agent**: Transmits cellular SMS alerts and warning cards.
- **Simulation Agent**: Runs virtual resolution steps, showing dynamic KPI improvements (e.g., Traffic Flow: 45% -> 80%, Ambulance ETA: 26 mins -> 12 mins).

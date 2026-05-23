from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Any, Set
import asyncio
import json
from app.config import settings
from app.orchestrator import CrisisOrchestrator

app = FastAPI(title="CrisisSync Backend", description="AI-powered Crisis Intelligence & Response Orchestrator")

# Enable CORS for local Flutter web or other frontend clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Store of completed simulations / active incident states
incidents_db: List[Dict[str, Any]] = []
active_simulation_state: Dict[str, Any] = {}

# Active WebSocket connections
connected_websockets: Set[WebSocket] = set()

# Initialize Firebase if credentials exist
firebase_enabled = False
if settings.firebase_credentials_path and settings.firebase_database_url:
    try:
        import firebase_admin
        from firebase_admin import credentials, db
        
        cred = credentials.Certificate(settings.firebase_credentials_path)
        firebase_admin.initialize_app(cred, {
            'databaseURL': settings.firebase_database_url
        })
        firebase_enabled = True
        print("[Firebase] Successfully connected to Firebase Realtime Database.")
    except Exception as e:
        print(f"[Firebase] Initialization failed: {e}. Running local-only mode.")

async def broadcast_state(payload: Dict[str, Any]):
    """Broadcasts current orchestrator step to all WebSockets & Firebase."""
    # 1. Update local DB
    global active_simulation_state
    active_simulation_state = payload
    
    if payload.get("step") == "outcome_simulation" and payload.get("incident"):
        # Incident resolved/mitigated, save to history list
        incidents_db.append(payload["incident"])

    # 2. Push to connected WebSockets
    dead_sockets = []
    for websocket in connected_websockets:
        try:
            await websocket.send_json(payload)
        except Exception:
            dead_sockets.append(websocket)
            
    for ws in dead_sockets:
        connected_websockets.remove(ws)

    # 3. Sync to Firebase Realtime Database
    if firebase_enabled:
        try:
            # Sync incident state
            ref = db.reference("crisis_sync")
            ref.child("active_simulation").set(payload)
            if payload.get("incident"):
                ref.child("incidents").child(payload["incident"]["id"]).set(payload["incident"])
        except Exception as e:
            print(f"[Firebase] Sync error: {e}")

@app.get("/")
def read_root():
    return {
        "status": "healthy",
        "app": "CrisisSync",
        "firebase_enabled": firebase_enabled,
        "active_connections": len(connected_websockets)
    }

@app.get("/api/incidents")
def get_incidents():
    """Retrieve historical incidents."""
    return incidents_db

@app.get("/api/active-simulation")
def get_active_simulation():
    """Retrieve the current active simulation state."""
    return active_simulation_state

@app.post("/api/simulate")
async def trigger_simulation(payload: Dict[str, Any]):
    """
    Trigger the multi-agent orchestration by sending raw signals.
    Example body:
    {
        "signals": [
            {"source": "social", "content": "G-10 mein pani bhar gaya hai, gaariyan phans gayi hain"},
            {"source": "weather", "content": "HEAVY RAINFALL WARNING: 50mm expected"},
            {"source": "traffic", "content": "Severe traffic congestion spike on Kashmir Highway"}
        ]
    }
    """
    signals = payload.get("signals")
    if not signals:
        raise HTTPException(status_code=400, detail="Missing list of signals to process.")

    # Create orchestrator with broadcast capability
    orchestrator = CrisisOrchestrator(broadcast_callback=broadcast_state)
    
    # Run async background pipeline so endpoint returns immediately (or waits for task start)
    # We will trigger the orchestration as an asynchronous background task so the frontend
    # can immediately receive the live WebSocket log updates step by step.
    asyncio.create_task(orchestrator.run_orchestration(signals))
    
    return {"status": "triggered", "message": "Multi-agent orchestration started."}

@app.websocket("/ws/live")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_websockets.add(websocket)
    print(f"[WebSocket] Client connected. Total: {len(connected_websockets)}")
    
    # Send the latest active simulation state upon joining
    if active_simulation_state:
        try:
            await websocket.send_json(active_simulation_state)
        except Exception:
            pass
            
    try:
        while True:
            # Keep connection alive, listen for any client messages
            data = await websocket.receive_text()
            # If client requests a manual inject, we can handle it
            try:
                msg = json.loads(data)
                if msg.get("type") == "trigger":
                    signals = msg.get("signals", [])
                    orchestrator = CrisisOrchestrator(broadcast_callback=broadcast_state)
                    asyncio.create_task(orchestrator.run_orchestration(signals))
            except Exception as e:
                print(f"[WebSocket] Error handling client message: {e}")
    except WebSocketDisconnect:
        connected_websockets.remove(websocket)
        print(f"[WebSocket] Client disconnected. Total: {len(connected_websockets)}")

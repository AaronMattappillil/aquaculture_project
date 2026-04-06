import os
import sys

# Ensure the backend directory is in the python path
backend_path = os.path.dirname(os.path.abspath(__file__))
if backend_path not in sys.path:
    sys.path.append(backend_path)

from app.main import app

if __name__ == "__main__":
    import uvicorn
    # Use PORT environment variable for deployment (e.g., Render)
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False if os.getenv("ENV") == "production" else True)

# Import FastAPI - the web framework that turns Python into a server
from fastapi import FastAPI
# Import CORSMiddleware - allows the HTML file to talk to Python from a different port
from fastapi.middleware.cors import CORSMiddleware
# Import os - used to read environment variables (like API keys)
import os
# Import load_dotenv - reads the .env file to load secret keys safely
from dotenv import load_dotenv

# Load the .env file so the API key is available in our code
load_dotenv()

# Create the FastAPI app - this is our main server object
app = FastAPI()

# Configure CORS (Cross-Origin Resource Sharing)
# This allows our HTML frontend to talk to this Python backend
# even though they run on different ports/origins
app.add_middleware(
    CORSMiddleware,
    # Allow requests from any origin (for development - in production you'd specify exact URLs)
    allow_origins=["*"],
    # Allow all HTTP methods (GET, POST, etc.)
    allow_methods=["*"],
    # Allow all headers (including Content-Type for JSON)
    allow_headers=["*"],
)

# Create a GET route at "/" - this is the root URL of our server
# When someone visits http://localhost:8000, this function runs
@app.get("/")
def read_root():
    # Return a JSON response with a message and status
    return {"message": "APWA is running", "status": "ok"}

# This block runs when the file is executed directly (not when imported)
if __name__ == "__main__":
    # Import uvicorn - the server that actually runs FastAPI
    import uvicorn
    # Start the server on host 0.0.0.0 (accessible from any network interface)
    # and port 8000 (the standard port for development servers)
    uvicorn.run(app, host="0.0.0.0", port=8000)

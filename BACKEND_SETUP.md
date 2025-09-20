# Chess Coach Backend Setup Guide 🚀

**For iOS Developers - No Backend Experience Required!**

This guide will help you set up the LLM Chess Coach API server so your iOS app can provide AI-powered chess coaching.

## Prerequisites ✅

You need these tools installed on your Mac:

### 1. Python 3.9+ (✅ You have Python 3.12.3)
```bash
python3 --version
# Should show: Python 3.12.3 or similar
```

### 2. Homebrew (for installing Stockfish)
If you don't have Homebrew, install it:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Step-by-Step Setup 📋

### Step 1: Install Stockfish Chess Engine
```bash
# Install Stockfish using Homebrew
brew install stockfish

# Verify installation
stockfish
# Type 'quit' to exit if it opens successfully
```

### Step 2: Set Up Python Environment
```bash
# Navigate to the backend directory
cd ../LLM-ChessCoach

# Create a virtual environment (recommended)
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate
# You should see (venv) in your terminal prompt

# Install required packages
pip3 install -r requirements.txt
```

### Step 3: Set Up OpenAI API (Optional but Recommended)
The coaching features work best with OpenAI's API for detailed analysis.

1. **Get an OpenAI API Key:**
   - Go to https://platform.openai.com/api-keys
   - Sign up/login and create a new API key
   - Copy the key (starts with `sk-`)

2. **Set up environment variables:**
```bash
# Create a .env file
touch .env

# Add your OpenAI API key (replace with your actual key)
echo "OPENAI_API_KEY=sk-your-api-key-here" >> .env
```

### Step 4: Test the Server
```bash
# Make sure you're in the LLM-ChessCoach directory
# and your virtual environment is activated (you should see (venv))

# Start the server
uvicorn api_server:app --reload --host 0.0.0.0 --port 8000
```

You should see output like:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [12345] using StatReload
INFO:     Started server process [12346]
INFO:     Waiting for application startup.
```

### Step 5: Test the API
Open a new terminal tab and test:
```bash
# Test the API is working
curl http://localhost:8000/v1/sessions -X POST

# You should get a response like:
# {"session_id":"abc123","fen_start":"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"}
```

## Quick Start Scripts 🎯

I've created easy scripts for you:

### Start Server Script
```bash
# Make the start script executable
chmod +x start_server.sh

# Start the server (from the ChessApp directory)
./start_server.sh
```

### Stop Server Script
```bash
# Stop the server
./stop_server.sh
```

## iOS App Configuration 📱

In your iOS app, the API is configured to connect to:
- **URL**: `http://localhost:8000`
- **No authentication required** for local development

## Troubleshooting 🔧

### Common Issues:

#### 1. "stockfish not found"
```bash
# Install Stockfish
brew install stockfish

# Verify it's in your PATH
which stockfish
```

#### 2. "ModuleNotFoundError"
```bash
# Make sure virtual environment is activated
source ../LLM-ChessCoach/venv/bin/activate

# Reinstall requirements
pip3 install -r ../LLM-ChessCoach/requirements.txt
```

#### 3. "Address already in use"
```bash
# Kill any existing server on port 8000
lsof -ti:8000 | xargs kill -9

# Then restart the server
uvicorn api_server:app --reload --host 0.0.0.0 --port 8000
```

#### 4. OpenAI API Issues
- Check your API key in `.env` file
- Verify you have credits in your OpenAI account
- The server will work without OpenAI but with limited coaching features

### Check Server Status
```bash
# Check if server is running
curl http://localhost:8000/v1/sessions -X POST

# Check server logs
# Look at the terminal where you started the server
```

## Development Workflow 🔄

### Daily Development:
1. **Start Backend**: `./start_server.sh`
2. **Open Xcode**: Build and run your iOS app
3. **Test Integration**: Make moves in the app to see coaching feedback
4. **Stop Backend**: `./stop_server.sh` when done

### Server URLs for Different Environments:
- **Local Development**: `http://localhost:8000`
- **iOS Simulator**: `http://localhost:8000`
- **Physical Device**: `http://YOUR_MAC_IP:8000` (get IP with `ifconfig`)

## API Endpoints Summary 📋

Your iOS app uses these endpoints:

- `POST /v1/sessions` - Create new coaching session
- `POST /v1/sessions/{id}/move?move=e4` - Analyze a move
- `GET /v1/sessions/{id}` - Get session status

## File Structure 📁

```
LLM-ChessCoach/
├── api_server.py          # Main server file
├── requirements.txt       # Python dependencies
├── stockfish_engine.py    # Chess engine wrapper
├── llm_coach.py          # AI coaching logic
├── live_sessions.py      # Session management
└── venv/                 # Virtual environment (after setup)
```

## Success! 🎉

When everything is working:
1. ✅ Server starts without errors
2. ✅ API test returns session data
3. ✅ iOS app shows "Connected" status
4. ✅ Making moves shows coaching feedback

Need help? Check the troubleshooting section or ask for assistance!
#!/bin/bash

# Chess Coach Backend Startup Script
# For iOS Developers - Easy server management

echo "🚀 Starting Chess Coach Backend Server..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if we're in the right directory
if [ ! -d "../LLM-ChessCoach" ]; then
    echo "❌ Error: LLM-ChessCoach directory not found!"
    echo "   Make sure you're running this from the ChessApp directory"
    exit 1
fi

# Navigate to backend directory
cd ../LLM-ChessCoach

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed!"
    echo "   Please install Python 3.9+ from https://python.org"
    exit 1
fi

# Check if Stockfish is installed
if ! command -v stockfish &> /dev/null; then
    echo "⚠️  Warning: Stockfish not found!"
    echo "   Installing Stockfish using Homebrew..."

    if ! command -v brew &> /dev/null; then
        echo "❌ Error: Homebrew not installed!"
        echo "   Please install Homebrew from https://brew.sh"
        exit 1
    fi

    brew install stockfish

    if ! command -v stockfish &> /dev/null; then
        echo "❌ Error: Failed to install Stockfish!"
        exit 1
    fi

    echo "✅ Stockfish installed successfully!"
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created!"
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install/update requirements
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to install requirements!"
    echo "   Try running: pip3 install -r requirements.txt"
    exit 1
fi

echo "✅ Dependencies installed!"

# Check for OpenAI API key
if [ ! -f ".env" ] || ! grep -q "OPENAI_API_KEY" .env; then
    echo ""
    echo "⚠️  OpenAI API Key not found!"
    echo "   For best coaching experience, add your OpenAI API key:"
    echo "   1. Get a key from: https://platform.openai.com/api-keys"
    echo "   2. Create .env file with: OPENAI_API_KEY=sk-your-key-here"
    echo "   3. The server will work without it, but with limited features"
    echo ""
fi

# Check if port 8000 is already in use
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null; then
    echo "⚠️  Port 8000 is already in use!"
    echo "   Killing existing server..."
    lsof -ti:8000 | xargs kill -9 2>/dev/null
    sleep 2
fi

echo ""
echo "🎯 Starting server on http://localhost:8000"
echo "   Press Ctrl+C to stop the server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start the server
uvicorn api_server:app --reload --host 0.0.0.0 --port 8000
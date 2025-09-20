#!/bin/bash

# Chess Coach Backend One-Time Setup Script
# For iOS Developers - Run this once to set everything up

echo "🎯 Chess Coach Backend Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "This will set up everything you need for the Chess Coach API"
echo ""

# Check if we're in the right directory
if [ ! -d "../LLM-ChessCoach" ]; then
    echo "❌ Error: LLM-ChessCoach directory not found!"
    echo "   Make sure you're running this from the ChessApp directory"
    exit 1
fi

# 1. Install Stockfish
echo "1️⃣  Installing Stockfish Chess Engine..."
if ! command -v stockfish &> /dev/null; then
    if ! command -v brew &> /dev/null; then
        echo "❌ Error: Homebrew not installed!"
        echo "   Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    echo "   Installing via Homebrew..."
    brew install stockfish

    if command -v stockfish &> /dev/null; then
        echo "   ✅ Stockfish installed successfully!"
    else
        echo "   ❌ Failed to install Stockfish"
        exit 1
    fi
else
    echo "   ✅ Stockfish already installed!"
fi

echo ""

# 2. Set up Python environment
echo "2️⃣  Setting up Python environment..."
cd ../LLM-ChessCoach

if [ ! -d "venv" ]; then
    echo "   Creating virtual environment..."
    python3 -m venv venv
    echo "   ✅ Virtual environment created!"
else
    echo "   ✅ Virtual environment already exists!"
fi

echo "   Activating virtual environment..."
source venv/bin/activate

echo "   Installing Python dependencies..."
pip3 install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "   ✅ Dependencies installed successfully!"
else
    echo "   ❌ Failed to install dependencies"
    exit 1
fi

echo ""

# 3. OpenAI API Key setup
echo "3️⃣  OpenAI API Key setup (optional)..."
if [ ! -f ".env" ] || ! grep -q "OPENAI_API_KEY" .env; then
    echo ""
    echo "   🔑 For the best coaching experience, you need an OpenAI API key:"
    echo "      1. Go to: https://platform.openai.com/api-keys"
    echo "      2. Sign up/login and create a new API key"
    echo "      3. Copy the key (starts with 'sk-')"
    echo ""
    read -p "   📝 Enter your OpenAI API key (or press Enter to skip): " api_key

    if [ ! -z "$api_key" ]; then
        echo "OPENAI_API_KEY=$api_key" > .env
        echo "   ✅ API key saved to .env file!"
    else
        echo "   ⚠️  Skipped - server will work with limited features"
    fi
else
    echo "   ✅ OpenAI API key already configured!"
fi

echo ""

# 4. Test the setup
echo "4️⃣  Testing the setup..."
echo "   Starting server for quick test..."

# Start server in background
uvicorn api_server:app --host 127.0.0.1 --port 8000 &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Test the API
echo "   Testing API connection..."
RESPONSE=$(curl -s -X POST http://localhost:8000/v1/sessions 2>/dev/null)

# Kill the test server
kill $SERVER_PID 2>/dev/null

if echo "$RESPONSE" | grep -q "session_id"; then
    echo "   ✅ API test successful!"
else
    echo "   ⚠️  API test failed - check the logs above"
fi

cd ../ChessApp

echo ""
echo "🎉 Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ What's ready:"
echo "   • Stockfish chess engine installed"
echo "   • Python environment configured"
echo "   • API dependencies installed"
if [ -f "../LLM-ChessCoach/.env" ]; then
    echo "   • OpenAI API key configured"
fi
echo ""
echo "🚀 Next steps:"
echo "   1. Start the server: ./start_server.sh"
echo "   2. Open Xcode and run your iOS app"
echo "   3. Enable coaching in the app and make moves!"
echo ""
echo "📖 Need help? Check BACKEND_SETUP.md for detailed instructions"
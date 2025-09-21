#!/bin/bash

# Chess Coach Backend Stop Script
# For iOS Developers - Easy server management

echo "🛑 Stopping Chess Coach Backend Server..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find and kill any process using port 8000
PIDS=$(lsof -ti:8000 2>/dev/null)

if [ -z "$PIDS" ]; then
    echo "ℹ️  No server running on port 8000"
else
    echo "🔍 Found server processes: $PIDS"
    echo "💀 Killing server processes..."

    # Kill the processes
    echo $PIDS | xargs kill -9 2>/dev/null

    # Wait a moment
    sleep 2

    # Check if any are still running
    REMAINING=$(lsof -ti:8000 2>/dev/null)
    if [ -z "$REMAINING" ]; then
        echo "✅ Server stopped successfully!"
    else
        echo "⚠️  Some processes may still be running: $REMAINING"
        echo "   You may need to kill them manually"
    fi
fi

echo ""
echo "🎯 Server cleanup complete!"
echo "   You can now start the server again with: ./start_server.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
#!/bin/bash

# ==============================================================================
# CONFIGURATION - CHANGE THESE PATHS ACCORDING TO YOUR UBUNTU ENVIRONMENT
# ==============================================================================
API_DIR="$HOME/navratri_app/api_server"
LOG_DIR="$HOME/navratri_app/logs"
NGROK_BIN="ngrok"          # Assumes ngrok is installed in your system PATH
DART_BIN="dart"            # Assumes Dart/Flutter SDK is added to system PATH
FLUTTER_BIN="flutter"      # Assumes Flutter is added to system PATH
# ==============================================================================

# Ensure log directory exists
mkdir -p "$LOG_DIR"

start_app() {
    clear
    echo "============================================"
    echo "   NAVRATRI 2026 - NISHPARK SOCIETY APP     "
    echo "============================================"
    echo ""

    echo " Stopping old servers..."
    pkill -f "dart" 2>/dev/null
    sudo systemctl stop nginx 2>/dev/null
    pkill -f "ngrok" 2>/dev/null
    sleep 2

    echo ""
    echo " [1/4] Checking PostgreSQL Database..."
    if systemctl is-active --quiet postgresql; then
        echo "        [OK] Database running!"
    else
        echo "        Starting PostgreSQL..."
        sudo systemctl start postgresql
        sleep 3
        if systemctl is-active --quiet postgresql; then
            echo "        [OK] Database started!"
        else
            echo "        [FAIL] Database failed to start. Ensure you have sudo permissions."
            read -p "Press Enter to continue..." confirm
            show_menu
            return
        fi
    fi

    echo " [2/4] Starting API Server (port 8080)..."
    cd "$API_DIR" || exit
    nohup "$DART_BIN" run bin/main.dart 8080 > "$LOG_DIR/api.log" 2>&1 &
    
    echo "        Waiting for API..."
    sleep 8
    
    if curl -s http://localhost:8080/api/daily-info >/dev/null 2>&1; then
        echo "        [OK] API + DB connected!"
    else
        echo "        [WARN] API not ready - check logs"
    fi

    echo " [3/4] Restarting Nginx (port 80)..."
    sudo systemctl restart nginx
    echo "        [OK] Nginx restarted!"

    echo " [4/4] Starting ngrok tunnel..."
    nohup $NGROK_BIN http 80 > "$LOG_DIR/ngrok.log" 2>&1 &
    sleep 5
    echo "        [OK] ngrok started!"

    show_menu
}

show_menu() {
    echo ""
    echo "============================================"
    echo ""
    echo "  Local:   http://localhost"
    echo "  API:     http://localhost:8080"
    echo "  Public:  https://ngrok-free.dev"
    echo ""
    echo "============================================"
    echo ""
    echo "  COMMANDS:"
    echo "    R  = Hot Restart  (restart API server only, keeps DB/nginx/ngrok)"
    echo "    F  = Full Restart (stop everything and start fresh)"
    echo "    H  = Hot Reload   (rebuild web + restart API)"
    echo "    L  = Show API logs"
    echo "    S  = Show status"
    echo "    Q  = Quit (stop all)"
    echo ""
    echo "============================================"
    echo ""
    
    handle_input
}

handle_input() {
    read -p "  > " CHOICE
    # Convert input to uppercase
    CHOICE=$(echo "$CHOICE" | tr '[:lower:]' '[:upper:]')

    case "$CHOICE" in
        "R")
            echo ""
            echo " Hot restarting API server..."
            pkill -f "dart run bin/main.dart" 2>/dev/null
            sleep 1
            cd "$API_DIR" || exit
            nohup "$DART_BIN" run bin/main.dart 8080 > "$LOG_DIR/api.log" 2>&1 &
            sleep 6
            if curl -s http://localhost:8080/api/daily-info >/dev/null 2>&1; then
                echo " [OK] API + DB reconnected!"
            else
                echo " [WARN] API not ready yet..."
            fi
            echo ""
            handle_input
            ;;
            
        "F")
            start_app
            ;;
            
        "H")
            echo ""
            echo " Rebuilding web and restarting API..."
            pkill -f "dart run bin/main.dart" 2>/dev/null
            echo " Building Flutter web..."
            cd "$API_DIR/.." || exit # Adjust if your root flutter project folder is different
            "$FLUTTER_BIN" build web --release --no-tree-shake-icons --no-pub > "$LOG_DIR/web_build.log" 2>&1
            
            echo " Restarting Nginx..."
            sudo systemctl restart nginx
            
            echo " Restarting API server..."
            cd "$API_DIR" || exit
            nohup "$DART_BIN" run bin/main.dart 8080 > "$LOG_DIR/api.log" 2>&1 &
            sleep 6
            if curl -s http://localhost:8080/api/daily-info >/dev/null 2>&1; then
                echo " [OK] Web rebuilt + API + DB reconnected!"
            else
                echo " [WARN] API not ready yet..."
            fi
            echo " TIP: Hard refresh browser (Ctrl+Shift+R) to clear cache."
            echo ""
            handle_input
            ;;
            
        "L")
            echo ""
            echo " === API LOGS (last 20 lines) ==="
            if [ -f "$LOG_DIR/api.log" ]; then
                tail -n 20 "$LOG_DIR/api.log"
            else
                echo " No logs yet."
            fi
            echo ""
            handle_input
            ;;
            
        "S")
            echo ""
            echo " === STATUS ==="
            systemctl is-active --quiet postgresql && echo " [OK] PostgreSQL: RUNNING" || echo " [OFF] PostgreSQL: STOPPED"
            pgrep -f "dart run bin/main.dart" >/dev/null && echo " [OK] API Server: RUNNING" || echo " [OFF] API Server: STOPPED"
            systemctl is-active --quiet nginx && echo " [OK] Nginx: RUNNING" || echo " [OFF] Nginx: STOPPED"
            pgrep -f "ngrok http" >/dev/null && echo " [OK] ngrok: RUNNING" || echo " [OFF] ngrok: STOPPED"
            curl -s http://localhost:8080/api/daily-info >/dev/null 2>&1 && echo " [OK] API Health: OK" || echo " [OFF] API Health: FAIL"
            echo ""
            handle_input
            ;;
            
        "Q")
            stop_app
            ;;
            
        *)
            echo " Unknown command. Use R, F, H, L, S, or Q."
            handle_input
            ;;
    esac
}

stop_app() {
    echo ""
    echo " Stopping all servers..."
    pkill -f "dart" 2>/dev/null
    pkill -f "ngrok" 2>/dev/null
    # Note: We keep system nginx/postgres running as standard Linux practices, 
    # but you can add 'sudo systemctl stop nginx' here if desired.
    sleep 2
    echo " Application services stopped!"
    echo "============================================"
    exit 0
}

# Initial Boot
start_app

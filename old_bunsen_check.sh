#!/bin/bash

# Default Settings
INPUT_FILE="urls.txt"
OUTPUT_DIR="bunsen_web_report"
TIMEOUT=5
TAKE_SCREENSHOT=true          # Default behavior
REFRESH_SPEED=5              # Default auto-refresh interval in seconds
COMPANY_NAME="Mega Genius Digital"
LOGO_FILE="mega_genius_digital_logo.png"

# HTML Reconstruction Engine Function (Runs on every loop)
rebuild_live_html_report() {
    local status_banner="$1"
    local meta_refresh="$2" # Optional parameter to handle live auto-refresh
    
    # Check if logo exists in output dir to determine header style
    local logo_html=""
    if [ -f "$OUTPUT_DIR/$LOGO_FILE" ]; then
        logo_html="<img src='$LOGO_FILE' alt='$COMPANY_NAME Logo' class='brand-logo'>"
    fi

    # 1. Write fresh HTML head structure
    cat <<EOF > "$REPORT_FILE"
<!DOCTYPE html>
<html>
<head>
    <title>$COMPANY_NAME - Web Triage Report</title>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    $meta_refresh
    <style>
        body { font-family: sans-serif; background: #222222; color: #eeeeee; padding: 20px; }
        .header-container { display: flex; align-items: center; gap: 20px; border-bottom: 2px solid #444444; padding-bottom: 15px; margin-bottom: 20px; }
        .brand-logo { max-height: 60px; width: auto; border: none; }
        .title-area h1 { margin: 0; font-size: 24px; color: #ffffff; }
        .title-area p { margin: 5px 0 0 0; font-size: 13px; color: #aaaaaa; }
        .card { background: #333333; border: 1px solid #444444; border-radius: 4px; padding: 15px; margin-bottom: 20px; display: flex; gap: 20px; }
        .info { flex: 2; }
        .screenshot { flex: 1; text-align: center; display: $([ "$TAKE_SCREENSHOT" = true ] && echo "block" || echo "none"); }
        img { max-width: 100%; max-height: 250px; border: 1px solid #555555; }
        pre { background: #111111; color: #a6e22e; padding: 10px; font-size: 11px; overflow-x: auto; max-height: 180px; }
        .badge { padding: 3px 8px; border-radius: 3px; font-weight: bold; color: #fff; }
        .status-200 { background: #27ae60; }
        .status-3xx { background: #2980b9; }
        .status-4xx { background: #d35400; }
        .status-error { background: #c0392b; }
        a { color: #3498db; text-decoration: none; }
        .banner { padding: 12px; border-radius: 4px; font-weight: bold; text-align: center; margin-bottom: 20px; }
    </style>
</head>
<body>
    
    <!-- Mega Genius Digital Corporate Header -->
    <div class="header-container">
        $logo_html
        <div class="title-area">
            <h1>$COMPANY_NAME</h1>
            <p>Web Asset Status & Visual Triage Report | Mode: $([ "$TAKE_SCREENSHOT" = true ] && echo "Full (Visual)" || echo "Fast (curl only)")</p>
        </div>
    </div>

    <p style="font-size: 12px; color: #888;">Generated on BunsenLabs: $(date)</p>
    $status_banner
EOF

    # 2. Append all historical completed entries
    cat "$CARDS_TMP" >> "$REPORT_FILE"

    # 3. Append closing tags
    echo "</body></html>" >> "$REPORT_FILE"
}

# Graceful Exit Handler (Triggers on Ctrl+C)
clean_exit_handler() {
    echo -e "\n\n[!] Ctrl+C detected! Saving collected data and closing report..."
    local abort_banner="<div class='banner' style='background: #c0392b; color: white;'>⚠️ Scan was manually aborted by user. Showing partial results below.</div>"
    rebuild_live_html_report "$abort_banner" "" 
    rm -f "$CARDS_TMP" "$CLEANED_URLS_TMP"
    exit 0
}

# Register the trap to capture SIGINT (Ctrl+C)
trap 'clean_exit_handler' SIGINT

# Parse command line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--no-screenshot) TAKE_SCREENSHOT=false; shift ;;
        -r|--refresh) 
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                REFRESH_SPEED=$2
                shift 2
            else
                echo "[-] Error: --refresh requires a numeric value (seconds)."
                exit 1
            fi
            ;;
        -h|--help) 
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -n, --no-screenshot       Skip browser screenshots, rely only on curl (Max Speed)"
            echo "  -r, --refresh [seconds]   Set custom browser auto-refresh interval (Default: 5)"
            echo "  -h, --help                Show this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Detect browser ONLY if screenshots are enabled
if [ "$TAKE_SCREENSHOT" = true ]; then
    if command -v chromium &> /dev/null; then
        BROWSER_CMD="chromium --headless --disable-gpu --window-size=1280,800"
    elif command -v firefox-esr &> /dev/null || command -v firefox &> /dev/null; then
        BROWSER_CMD="firefox-esr --headless --screenshot"
        command -v firefox &> /dev/null && [[ ! -x $(command -v firefox-esr) ]] && BROWSER_CMD="firefox --headless --screenshot"
    else
        echo "[-] Browser not found. Forcing fast mode (no screenshots)."
        TAKE_SCREENSHOT=false
    fi
fi

# Verify input targets file
if [ ! -f "$INPUT_FILE" ]; then
    echo "[-] Error: Please create an '$INPUT_FILE' file with your target URLs."
    exit 1
fi

# Filter duplicates and empty lines
echo "[*] Parsing targets... removing duplicate and blank entries."
CLEANED_URLS_TMP=$(mktemp)
awk '!/^\s*(#|$)/ && !seen[$0]++' "$INPUT_FILE" > "$CLEANED_URLS_TMP"
total_urls=$(wc -l < "$CLEANED_URLS_TMP")

if [ "$total_urls" -eq 0 ]; then
    echo "[-] Error: No valid targets found in '$INPUT_FILE' after filtering."
    rm -f "$CLEANED_URLS_TMP"
    exit 1
fi

# Setup output directories
mkdir -p "$OUTPUT_DIR"
if [ "$TAKE_SCREENSHOT" = true ]; then
    mkdir -p "$OUTPUT_DIR/screenshots"
fi

# Copy company logo to output directory if present locally
if [ -f "$LOGO_FILE" ]; then
    cp "$LOGO_FILE" "$OUTPUT_DIR/"
fi

REPORT_FILE="$OUTPUT_DIR/report.html"
CARDS_TMP=$(mktemp)

# Set up active banners and dynamic auto-refresh meta tags
active_banner="<div class='banner' style='background: #2980b9; color: white;'>🔄 Scan in progress... Page auto-refreshes every ${REFRESH_SPEED} seconds.</div>"
refresh_tag="<meta http-equiv=\"refresh\" content=\"${REFRESH_SPEED}\">"

# Initialize the HTML framework BEFORE opening the browser
rebuild_live_html_report "$active_banner" "$refresh_tag"
count=0

echo "[+] Initialized report frame at '$REPORT_FILE'"
echo "[+] Launching your default browser automatically..."
echo "--------------------------------------------------------"

# Auto-launch the default browser
xdg-open "$REPORT_FILE" &> /dev/null &

# Loop over the unique filtered URLs
while IFS= read -r url; do
    ((count++))
    
    echo "[*] [$count/$total_urls] Scanning: $url"
    safe_name=$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g')
    screenshot_path="screenshots/${safe_name}.png"
    
    # Check HTTP Status Code via curl (Fast Header Request)
    header_file=$(mktemp)
    status_code=$(curl -Is --connect-timeout $TIMEOUT -m $TIMEOUT "$url" -o "$header_file" -w "%{http_code}")
    
    if [ "$status_code" -eq 000 ] || [ -z "$status_code" ]; then
        status_code="OFFLINE"
        badge_class="status-error"
        headers="Connection failed, timed out, or DNS issue."
    else
        headers=$(cat "$header_file" | tr -d '\r')
        if [[ "$status_code" =~ ^2 ]]; then badge_class="status-200";
        elif [[ "$status_code" =~ ^3 ]]; then badge_class="status-3xx";
        else badge_class="status-4xx"; fi
    fi
    rm -f "$header_file"

    # Handle Screenshot optionally
    screenshot_element=""
    if [ "$TAKE_SCREENSHOT" = true ]; then
        if [ "$status_code" != "OFFLINE" ]; then
            echo "    └─ Capturing live screenshot layout..."
            if [[ "$BROWSER_CMD" == *"chromium"* ]]; then
                $BROWSER_CMD --screenshot="$OUTPUT_DIR/$screenshot_path" "$url" &> /dev/null
            else
                (cd "$OUTPUT_DIR/screenshots" && $BROWSER_CMD "${safe_name}.png" "$url") &> /dev/null
            fi
            screenshot_element="<img src='$screenshot_path' alt='Web Preview'>"
        else
            screenshot_element="<p style='color:#c0392b; font-weight:bold;'>Host Unreachable</p>"
        fi
        screenshot_element="<div class='screenshot'>$screenshot_element</div>"
    fi

    # Append data block directly to temporary container
    cat <<EOF >> "$CARDS_TMP"
    <div class="card">
        <div class="info">
            <h3><a href="$url" target="_blank">$url</a></h3>
            <p>Status Code: <span class="badge $badge_class">$status_code</span></p>
            <h4>Headers:</h4>
            <pre>$headers</pre>
        </div>
        $screenshot_element
    </div>
EOF

    # Recompile report layout on the fly
    rebuild_live_html_report "$active_banner" "$refresh_tag"

done < "$CLEANED_URLS_TMP"

# Finalize report structure cleanly and remove the browser refresh tag
success_banner="<div class='banner' style='background: #27ae60; color: white;'>✅ Scan fully completed successfully!</div>"
rebuild_live_html_report "$success_banner" ""

rm -f "$CARDS_TMP" "$CLEANED_URLS_TMP"
echo "--------------------------------------------------------"
echo "[+] All Done! Final updates compiled cleanly inside '$OUTPUT_DIR/report.html'."

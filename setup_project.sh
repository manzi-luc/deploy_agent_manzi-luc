#!/bin/bash

cleanup() {
    echo ""
    echo "Interrupt detected! Saving current state..."
    tar -czf "attendance_tracker_${INPUT}_archive.tar.gz" "${BASE_DIR}" 2>/dev/null
    rm -rf "${BASE_DIR}"
    echo "Archive saved as: attendance_tracker_${INPUT}_archive.tar.gz"
    echo "Incomplete directory removed. Exiting."
    exit 1
}

trap cleanup SIGINT

echo "=== Attendance Tracker Project Setup ==="
read -p "Enter a project identifier (e.g. batch1): " INPUT

if [ -z "${INPUT}" ]; then
    echo "Error: name cannot be empty. Exiting."
    exit 1
fi

BASE_DIR="attendance_tracker_${INPUT}"

echo "Creating project structure..."
mkdir -p "${BASE_DIR}/Helpers"
mkdir -p "${BASE_DIR}/reports"

echo "Creating config.json..."
cat > "${BASE_DIR}/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

echo "Creating assets.csv..."
cat > "${BASE_DIR}/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

echo "Creating reports.log..."
cat > "${BASE_DIR}/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

echo "Creating attendance_checker.py..."
cat > "${BASE_DIR}/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

echo "All files created."

echo ""
read -p "Do you want to update attendance thresholds? (y/n): " UPDATE

if [ "${UPDATE}" = "y" ] || [ "${UPDATE}" = "Y" ]; then

    read -p "Enter WARNING threshold % (default 75): " WARN_VAL
    read -p "Enter FAILURE threshold % (default 50): " FAIL_VAL

    if [[ -z "${WARN_VAL}" || ! "${WARN_VAL}" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Using default: 75"
        WARN_VAL=75
    fi

    if [[ -z "${FAIL_VAL}" || ! "${FAIL_VAL}" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Using default: 50"
        FAIL_VAL=50
    fi

    sed -i "s/\"warning\": [0-9]*/\"warning\": ${WARN_VAL}/" \
        "${BASE_DIR}/Helpers/config.json"

    sed -i "s/\"failure\": [0-9]*/\"failure\": ${FAIL_VAL}/" \
        "${BASE_DIR}/Helpers/config.json"

    echo "Thresholds updated: warning=${WARN_VAL}%, failure=${FAIL_VAL}%"
else
    echo "Keeping defaults: warning=75%, failure=50%"
fi

echo ""
echo "=== Health Check ==="

if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1)
    echo "✓ python3 found: ${PY_VER}"
else
    echo "⚠ python3 NOT found. Install from https://python.org"
fi

echo ""
echo "=== File Structure Verification ==="
for REQUIRED_PATH in \
    "${BASE_DIR}/attendance_checker.py" \
    "${BASE_DIR}/Helpers/assets.csv" \
    "${BASE_DIR}/Helpers/config.json" \
    "${BASE_DIR}/reports/reports.log"; do
    if [ -f "${REQUIRED_PATH}" ]; then
        echo "  ✓ ${REQUIRED_PATH}"
    else
        echo "  ✗ MISSING: ${REQUIRED_PATH}"
    fi
done

echo ""
echo "=== Setup Complete! ==="
echo "Project folder: ${BASE_DIR}/"
echo "To run the tracker:"
echo "  cd ${BASE_DIR} && python3 attendance_checker.py"

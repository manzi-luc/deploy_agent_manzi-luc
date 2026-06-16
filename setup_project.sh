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

cat > "${BASE_DIR}/Helpers/config.json" << 'EOF'
{
    "warning_threshold": 75,
    "failure_threshold": 50
}
EOF

cat > "${BASE_DIR}/Helpers/assets.csv" << 'EOF'
StudentID,Name,Attendance
001,Alice Mugisha,82
002,Bob Nkusi,48
003,Carol Uwase,71
004,David Habimana,55
005,Eve Mutesi,90
EOF

touch "${BASE_DIR}/reports/reports.log"

cat > "${BASE_DIR}/attendance_checker.py" << 'EOF'
import json
import csv

with open("Helpers/config.json") as f:
    config = json.load(f)

WARNING = config["warning_threshold"]
FAILURE = config["failure_threshold"]

log_lines = []

with open("Helpers/assets.csv") as f:
    reader = csv.DictReader(f)
    for row in reader:
        pct = int(row["Attendance"])
        if pct < FAILURE:
            status = "FAIL"
        elif pct < WARNING:
            status = "WARNING"
        else:
            status = "OK"
        line = f"{row['Name']}: {pct}% - {status}"
        print(line)
        log_lines.append(line)

with open("reports/reports.log", "w") as f:
    f.write("\n".join(log_lines))

print("\nReport saved to reports/reports.log")
EOF

echo "Files created."

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

    sed -i "s/\"warning_threshold\": [0-9]*/\"warning_threshold\": ${WARN_VAL}/" \
        "${BASE_DIR}/Helpers/config.json"

    sed -i "s/\"failure_threshold\": [0-9]*/\"failure_threshold\": ${FAIL_VAL}/" \
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

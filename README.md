# deploy_agent_manzi-luc

Automated shell script that bootstraps a Student Attendance Tracker project.

## How to run

1. Clone this repository
   git clone https://github.com/manzi-luc/deploy_agent_manzi-luc.git
   cd deploy_agent_manzi-luc

2. Make the script executable
   chmod +x setup_project.sh

3. Run it
   ./setup_project.sh

4. Follow the prompts:
   - Enter a project name (e.g. batch1)
   - Choose whether to update attendance thresholds
   - Script will create the full project structure automatically

## How to trigger the archive feature

Press Ctrl+C at ANY point while the script is running.

The script will:
1. Catch the interrupt signal (SIGINT)
2. Bundle everything created so far into attendance_tracker_{name}_archive.tar.gz
3. Delete the incomplete project directory
4. Exit cleanly

## Project structure created

attendance_tracker_{name}/
├── attendance_checker.py
├── Helpers/
│   ├── config.json
│   └── assets.csv
└── reports/
    └── reports.log# deploy_agent_manzi-luc

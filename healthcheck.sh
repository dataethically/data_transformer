#!/bin/bash

# Check if cron is running
if ! pgrep cron > /dev/null; then
  echo "Cron is not running"
  exit 1
fi

# Check if log file exists and has recent entries
if [ -f /var/log/cron.log ]; then
  if [ -z "$(find /var/log/cron.log -mmin -60)" ]; then
    echo "No recent cron activity"
    exit 1
  fi
fi

# Check database connection
if ! pg_isready -h $DB_HOST -U $DB_USER; then
  echo "Database connection failed"
  exit 1
fi

echo "Health check passed"
exit 0

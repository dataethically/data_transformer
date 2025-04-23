#!/bin/bash

echo "Starting data transformation at $(date)"

# Run weather data transformation
echo "Transforming weather data..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f /scripts/transform_weather.sql

echo "Transformation completed at $(date)"

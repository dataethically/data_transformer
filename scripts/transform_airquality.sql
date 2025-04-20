-- Transform raw air quality data into normalized tables
BEGIN;

-- First, let's extract the location data and ensure we have city records
-- Note: AirNow API returns location differently, so we need to extract it carefully
WITH air_locations AS (
    SELECT 
        id,
        json_array_elements(data) AS air_data
    FROM raw_airquality_data
)
INSERT INTO cities (city_name, latitude, longitude, country)
SELECT DISTINCT 
    json_extract_path_text(air_data, 'ReportingArea'),
    (json_extract_path_text(air_data, 'Latitude'))::float,
    (json_extract_path_text(air_data, 'Longitude'))::float,
    COALESCE(json_extract_path_text(air_data, 'CountryCode'), 'US')
FROM air_locations
WHERE json_extract_path_text(air_data, 'ReportingArea') IS NOT NULL
ON CONFLICT (city_name, country) DO NOTHING;

-- Now process the air quality measurements
WITH air_data_expanded AS (
    SELECT 
        id,
        json_array_elements(data) AS air_data
    FROM raw_airquality_data
)
INSERT INTO air_quality_measurements (
    city_id,
    measurement_time,
    aqi,
    pollutant_id,
    concentration,
    category
)
SELECT
    c.id,
    to_timestamp(json_extract_path_text(a.air_data, 'DateObserved') || ' ' || 
                json_extract_path_text(a.air_data, 'HourObserved') || ':00', 'MM/DD/YYYY HH24:MI'),
    (json_extract_path_text(a.air_data, 'AQI'))::integer,
    p.id,
    (json_extract_path_text(a.air_data, 'Concentration'))::decimal,
    json_extract_path_text(a.air_data, 'Category')
FROM air_data_expanded a
JOIN cities c ON c.city_name = json_extract_path_text(a.air_data, 'ReportingArea')
                AND c.country = COALESCE(json_extract_path_text(a.air_data, 'CountryCode'), 'US')
JOIN pollutants p ON p.name = json_extract_path_text(a.air_data, 'ParameterName')
ON CONFLICT (city_id, measurement_time, pollutant_id) DO NOTHING;

-- Clear processed raw data
DELETE FROM raw_airquality_data;

COMMIT;

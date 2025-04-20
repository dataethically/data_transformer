-- Transform raw weather data into normalized tables
BEGIN;

-- Extract city information and insert into cities table
INSERT INTO cities (city_name, latitude, longitude, country)
SELECT DISTINCT 
    json_extract_path_text(data, 'name'),
    (json_extract_path_text(data, 'coord', 'lat'))::float,
    (json_extract_path_text(data, 'coord', 'lon'))::float,
    json_extract_path_text(data, 'sys', 'country')
FROM raw_weather_data
ON CONFLICT (city_name, country) DO NOTHING;

-- Extract weather conditions and insert into weather_conditions table
INSERT INTO weather_conditions (condition_name)
SELECT DISTINCT 
    json_extract_path_text(data, 'weather', '0', 'main')
FROM raw_weather_data
WHERE json_extract_path_text(data, 'weather', '0', 'main') IS NOT NULL
ON CONFLICT (condition_name) DO NOTHING;

-- Insert weather measurements
INSERT INTO weather_measurements (
    city_id,
    measurement_time,
    temperature,
    feels_like,
    humidity,
    pressure,
    wind_speed,
    wind_direction,
    weather_condition_id
)
SELECT
    c.id,
    to_timestamp((json_extract_path_text(r.data, 'dt'))::bigint),
    (json_extract_path_text(r.data, 'main', 'temp'))::float,
    (json_extract_path_text(r.data, 'main', 'feels_like'))::float,
    (json_extract_path_text(r.data, 'main', 'humidity'))::float,
    (json_extract_path_text(r.data, 'main', 'pressure'))::float,
    (json_extract_path_text(r.data, 'wind', 'speed'))::float,
    (json_extract_path_text(r.data, 'wind', 'deg'))::float,
    wc.id
FROM raw_weather_data r
JOIN cities c ON c.city_name = json_extract_path_text(r.data, 'name')
               AND c.country = json_extract_path_text(r.data, 'sys', 'country')
JOIN weather_conditions wc ON wc.condition_name = json_extract_path_text(r.data, 'weather', '0', 'main')
ON CONFLICT (city_id, measurement_time) DO NOTHING;

-- Clear processed raw data
DELETE FROM raw_weather_data;

COMMIT;

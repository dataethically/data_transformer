FROM postgres:14

# Install required packages
RUN apt-get update && apt-get -y install cron curl

# Create directories
RUN mkdir -p /scripts

# Copy scripts
COPY scripts/transform_weather.sql /scripts/
COPY scripts/transform_airquality.sql /scripts/
COPY scripts/run_transformations.sh /scripts/

# Make scripts executable
RUN chmod +x /scripts/run_transformations.sh

# Set up cron job for scheduled execution
COPY crontab /etc/cron.d/transform-cron
RUN chmod 0644 /etc/cron.d/transform-cron
RUN crontab /etc/cron.d/transform-cron

# Create a health check script
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Set up health check
HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD /healthcheck.sh

# Run cron in foreground
CMD ["cron", "-f"]

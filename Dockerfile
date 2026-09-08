FROM docker.litellm.ai/berriai/litellm-database:v1.100.0

COPY config.yaml /app/config.yaml

CMD ["--config", "/app/config.yaml", "--port", "4000"]

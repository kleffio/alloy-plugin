FROM grafana/alloy:v1.3.1 AS alloy-bin

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/alloy /var/lib/alloy/data
COPY --from=alloy-bin /bin/alloy /bin/alloy
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

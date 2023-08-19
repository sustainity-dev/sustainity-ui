FROM debian:12.0-slim

COPY artifacts/sustainity_backend /bin/

RUN chmod +x /bin/sustainity_backend && \
    mkdir /etc/sustainity

CMD ["/bin/sustainity_backend"]

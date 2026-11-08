FROM python:3.13-alpine
ARG APP_VERSION=dev
ENV APP_VERSION=$APP_VERSION
WORKDIR /app
COPY server.py .
USER 65534
EXPOSE 8080
CMD ["python", "-u", "server.py"]

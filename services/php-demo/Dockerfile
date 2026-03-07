FROM php:8.3-cli-alpine
WORKDIR /app
COPY index.php .
RUN addgroup -S app && adduser -S -G app app
USER app
EXPOSE 8000
CMD ["php", "-S", "0.0.0.0:8000", "index.php"]

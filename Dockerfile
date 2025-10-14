# Imagem base com PHP + Apache
FROM moodlehq/moodle-php-apache:8.2

RUN apt-get update && apt-get install -y git unzip && rm -rf /var/lib/apt/lists/*

ENV MOODLE_VERSION=4.5

# Derive correct stable branch name (e.g., 4.5 -> MOODLE_405_STABLE) in POSIX sh
RUN set -e; \
    major=$(printf '%s' "$MOODLE_VERSION" | cut -d. -f1); \
    minor=$(printf '%s' "$MOODLE_VERSION" | cut -d. -f2); \
    minor_padded=$(printf '%02d' "$minor"); \
    BRANCH="MOODLE_${major}${minor_padded}_STABLE"; \
    echo "Cloning Moodle branch: $BRANCH"; \
    git clone --depth 1 -b "$BRANCH" https://github.com/moodle/moodle /var/www/html

RUN chown -R www-data:www-data /var/www/html

# ...existing code...
# Usa entrypoint para gerar o config.php a partir das variáveis de ambiente
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
# ...existing code...

EXPOSE 80
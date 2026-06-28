#!/usr/bin/env bash
# Деплой single-tenant B24 local-app.
# Синхронизирует www/ → /var/www/b24/<slug>/
# env.php, data/, init.php — не трогает (прод-конфиг, store, bootstrap).
#
# Slug = имя папки проекта. Создать папку и env.php — через init.php в браузере.

set -euo pipefail
cd "$(dirname "$0")"

SLUG="$(basename "$(pwd)")"

# Safety: slug должен быть простым идентификатором.
if ! [[ "$SLUG" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Ошибка: slug '${SLUG}' содержит недопустимые символы. Только [a-zA-Z0-9_-]." >&2
  exit 1
fi

DEPLOY_DIR="/var/www/b24/${SLUG}"
mkdir -p "$DEPLOY_DIR"

if command -v rsync &>/dev/null; then
  rsync -avz --delete \
    --exclude 'env.php' \
    --exclude 'data/' \
    --exclude 'init.php' \
    --exclude '.git/' \
    --exclude '*.example' \
    www/ "$DEPLOY_DIR/"
else
  cp -a www/. "$DEPLOY_DIR/"
  rm -f "$DEPLOY_DIR/env.php" "$DEPLOY_DIR/init.php"
fi

# data/ должна быть доступна для записи PHP-FPM (www-data).
# Содержимое защищено <?php exit;?>, не правами ФС.
mkdir -p "$DEPLOY_DIR/data"
chmod 0777 "$DEPLOY_DIR/data"

echo "✓ Деплой завершён: https://b24.blackboxbegin.space/${SLUG}/"
echo "  Первый запуск? Открой: https://b24.blackboxbegin.space/${SLUG}/init.php"

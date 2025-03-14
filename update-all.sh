#!/bin/bash

REPO_LIST=~/.repo-autosync.list
LOG=~/repo-sync.log

if [ ! -f "$REPO_LIST" ]; then
  echo "📄 Список $REPO_LIST не найден. Создаю..."
  touch "$REPO_LIST"
fi

mapfile -t REPOS < "$REPO_LIST"

for REPO in "${REPOS[@]}"; do
  echo "📁 Обрабатываем: $REPO" | tee -a "$LOG"
  cd "$REPO" || { echo "❌ Не удалось войти в $REPO" | tee -a "$LOG"; continue; }

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "⚠️ Это не Git-репозиторий: $REPO" | tee -a "$LOG"
    continue
  fi

  branch=$(git rev-parse --abbrev-ref HEAD)
  if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    NOW=$(date "+%Y-%m-%d %H:%M:%S")
    echo "🔄 Изменения найдены в ветке $branch" | tee -a "$LOG"
    git add .
    git commit -m "🔁 Auto commit at $NOW" || echo "⚠️ Нечего коммитить" | tee -a "$LOG"
    git pull --rebase origin "$branch"
    git push origin "$branch"
    echo "✅ Обновлено: $REPO [$branch]" | tee -a "$LOG"
  else
    echo "✅ Нет изменений: $REPO [$branch]" | tee -a "$LOG"
  fi

  echo "----------------------------------------" | tee -a "$LOG"
done

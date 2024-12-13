#!/usr/bin/with-contenv bashio
set -e
bashio::log.warning "This add-on has been moved to a new GitHub repository. See more in the Home Assistant notification."
bashio::log.warning "The new home of my addons is: https://github.com/Poeschl-HomeAssistant-Addons/repository"
bashio::log.warning "A migration guide is available here: https://github.com/Poeschl-HomeAssistant-Addons/repository/blob/main/docs/migrate_from_Poeschl_repository.md"

if ! command -v curl > /dev/null; then
  if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install -y --no-install-recommends curl
    apt-get clean
    rm -rf /var/lib/apt/lists/*
  elif [ -f /etc/alpine-release ]; then
    apk add --no-cache curl
  fi
fi

addon_name=$(bashio::addon.name)

curl -X POST -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" -H "Content-Type: application/json" \
  --data "{\"notification_id\": \"Poeschl_addon_notify_${addon_name}\", \"title\": \"Poeschl Add-ons - Repository Move\", \"message\": \"The repository of Poeschl Add-ons has moved.\nPlease look at the start logs of ${addon_name} for a migration guide.\"}" \
  http://supervisor/core/api/services/persistent_notification/create

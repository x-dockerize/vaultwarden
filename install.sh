#!/usr/bin/env bash
set -e

ENV_EXAMPLE=".env.example"
ENV_FILE=".env"

# --------------------------------------------------
# Kontroller
# --------------------------------------------------
if [ ! -f "$ENV_EXAMPLE" ]; then
  echo "❌ $ENV_EXAMPLE bulunamadı."
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo "✅ $ENV_EXAMPLE → $ENV_FILE kopyalandı"
else
  echo "ℹ️  $ENV_FILE mevcut, güncellenecek"
fi

# --------------------------------------------------
# Yardımcı Fonksiyonlar
# --------------------------------------------------
gen_token() {
  openssl rand -hex 32
}

set_env() {
  local key="$1"
  local value="$2"

  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

set_env_once() {
  local key="$1"
  local value="$2"

  local current
  current=$(grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)

  if [ -z "$current" ]; then
    set_env "$key" "$value"
  fi
}

# --------------------------------------------------
# Kullanıcıdan Gerekli Bilgiler
# --------------------------------------------------
read -rp "VAULTWARDEN_SERVER_HOSTNAME (örn: vault.example.com): " VAULTWARDEN_SERVER_HOSTNAME

echo
echo "--- Kayıt Ayarları ---"
read -rp "SIGNUPS_DOMAINS_WHITELIST (örn: example.com — boş bırakılırsa herkese kapalı): " SIGNUPS_DOMAINS_WHITELIST

echo
read -rp "SMTP ayarlamak ister misin? (e/h): " SETUP_SMTP

if [[ "$SETUP_SMTP" =~ ^[Ee]$ ]]; then
  echo
  echo "--- SMTP Ayarları ---"
  read -rp "SMTP_HOST (örn: live.smtp.mailtrap.io): " SMTP_HOST
  read -rp "SMTP_PORT (boş bırakılırsa: 587): " INPUT_SMTP_PORT
  SMTP_PORT="${INPUT_SMTP_PORT:-587}"
  read -rp "SMTP_USERNAME: " SMTP_USERNAME
  read -rsp "SMTP_PASSWORD: " SMTP_PASSWORD
  echo
  read -rp "SMTP_FROM (örn: vault@example.com): " SMTP_FROM
fi

# --------------------------------------------------
# .env Güncelle
# --------------------------------------------------
set_env VAULTWARDEN_SERVER_HOSTNAME "$VAULTWARDEN_SERVER_HOSTNAME"

if [ -n "$SIGNUPS_DOMAINS_WHITELIST" ]; then
  set_env SIGNUPS_ALLOWED            "false"
  set_env SIGNUPS_DOMAINS_WHITELIST  "$SIGNUPS_DOMAINS_WHITELIST"
else
  set_env SIGNUPS_ALLOWED            "false"
fi

if [[ "$SETUP_SMTP" =~ ^[Ee]$ ]]; then
  set_env SMTP_HOST     "$SMTP_HOST"
  set_env SMTP_PORT     "$SMTP_PORT"
  set_env SMTP_USERNAME "$SMTP_USERNAME"
  set_env SMTP_PASSWORD "$SMTP_PASSWORD"
  set_env SMTP_FROM     "$SMTP_FROM"
fi

# Admin token — mevcut değerin üzerine yazılmaz
set_env_once ADMIN_TOKEN "$(gen_token)"

ADMIN_TOKEN=$(grep "^ADMIN_TOKEN=" "$ENV_FILE" | cut -d'=' -f2-)

# --------------------------------------------------
# Sonuçları Göster
# --------------------------------------------------
echo
echo "==============================================="
echo "✅ Vaultwarden .env başarıyla hazırlandı!"
echo "-----------------------------------------------"
echo "🌐 Hostname      : https://$VAULTWARDEN_SERVER_HOSTNAME"
echo "🔑 Admin Token   : $ADMIN_TOKEN"
echo "-----------------------------------------------"
echo "⚠️  Admin token'ı güvenli bir yerde saklayın!"
echo "==============================================="

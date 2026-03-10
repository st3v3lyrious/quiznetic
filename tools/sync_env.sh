#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-$ROOT_DIR/.env}"
IOS_ENV_XCCONFIG="$ROOT_DIR/ios/Flutter/Env.xcconfig"
ANDROID_GOOGLE_SERVICES_JSON="$ROOT_DIR/android/app/google-services.json"
IOS_GOOGLE_SERVICE_INFO_PLIST="$ROOT_DIR/ios/Runner/GoogleService-Info.plist"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE"
  echo "Create it from .env.example first."
  exit 1
fi

trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

parse_env_value() {
  local raw_value="$1"
  local line_number="$2"

  if [[ -z "$raw_value" ]]; then
    printf '%s' ""
    return 0
  fi

  if [[ "$raw_value" == \"* ]]; then
    if [[ ${#raw_value} -lt 2 || "${raw_value: -1}" != '"' ]]; then
      echo "Invalid env line $line_number in $ENV_FILE: unmatched double quote" >&2
      exit 1
    fi
    printf '%s' "${raw_value:1:${#raw_value}-2}"
    return 0
  fi

  if [[ "$raw_value" == \'* ]]; then
    if [[ ${#raw_value} -lt 2 || "${raw_value: -1}" != "'" ]]; then
      echo "Invalid env line $line_number in $ENV_FILE: unmatched single quote" >&2
      exit 1
    fi
    printf '%s' "${raw_value:1:${#raw_value}-2}"
    return 0
  fi

  printf '%s' "$raw_value"
}

load_env_file() {
  local raw_line=""
  local trimmed=""
  local key=""
  local raw_value=""
  local parsed_value=""
  local line_number=0

  while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line_number=$((line_number + 1))
    raw_line="${raw_line%$'\r'}"
    trimmed="$(trim_whitespace "$raw_line")"

    if [[ -z "$trimmed" || "${trimmed:0:1}" == "#" ]]; then
      continue
    fi

    if [[ "$trimmed" == export[[:space:]]* ]]; then
      trimmed="$(trim_whitespace "${trimmed#export}")"
    fi

    if [[ ! "$trimmed" =~ ^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*= ]]; then
      echo "Invalid env line $line_number in $ENV_FILE: expected KEY=VALUE" >&2
      exit 1
    fi

    key="$(trim_whitespace "${trimmed%%=*}")"
    raw_value="$(trim_whitespace "${trimmed#*=}")"
    parsed_value="$(parse_env_value "$raw_value" "$line_number")"
    printf -v "$key" '%s' "$parsed_value"
  done < "$ENV_FILE"
}

load_env_file

required_vars=(
  FIREBASE_PROJECT_NUMBER
  FIREBASE_ANDROID_API_KEY
  FIREBASE_ANDROID_APP_ID
  FIREBASE_ANDROID_PROJECT_ID
  FIREBASE_ANDROID_STORAGE_BUCKET
  FIREBASE_ANDROID_PACKAGE_NAME
  FIREBASE_ANDROID_CERT_HASH
  FIREBASE_ANDROID_OAUTH_CLIENT_ID
  FIREBASE_IOS_OAUTH_CLIENT_ID
  FIREBASE_IOS_API_KEY
  FIREBASE_IOS_APP_ID
  FIREBASE_IOS_MESSAGING_SENDER_ID
  FIREBASE_IOS_PROJECT_ID
  FIREBASE_IOS_STORAGE_BUCKET
  FIREBASE_IOS_BUNDLE_ID
)

missing_vars=()
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    missing_vars+=("$var_name")
  fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
  echo "Missing required variables in $ENV_FILE:"
  for var_name in "${missing_vars[@]}"; do
    echo "  - $var_name"
  done
  exit 1
fi

cat > "$IOS_ENV_XCCONFIG" <<EOF
// Generated from $(basename "$ENV_FILE"). Do not commit this file.
ADS_IOS_APP_ID=${ADS_IOS_APP_ID:-}
EOF

cat > "$ANDROID_GOOGLE_SERVICES_JSON" <<EOF
{
  "project_info": {
    "project_number": "${FIREBASE_PROJECT_NUMBER}",
    "project_id": "${FIREBASE_ANDROID_PROJECT_ID}",
    "storage_bucket": "${FIREBASE_ANDROID_STORAGE_BUCKET}"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "${FIREBASE_ANDROID_APP_ID}",
        "android_client_info": {
          "package_name": "${FIREBASE_ANDROID_PACKAGE_NAME}"
        }
      },
      "oauth_client": [
        {
          "client_id": "${FIREBASE_ANDROID_OAUTH_CLIENT_ID}",
          "client_type": 1,
          "android_info": {
            "package_name": "${FIREBASE_ANDROID_PACKAGE_NAME}",
            "certificate_hash": "${FIREBASE_ANDROID_CERT_HASH}"
          }
        },
        {
          "client_id": "${GOOGLE_OAUTH_CLIENT_ID:-}",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "${FIREBASE_ANDROID_API_KEY}"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "${GOOGLE_OAUTH_CLIENT_ID:-}",
              "client_type": 3
            },
            {
              "client_id": "${FIREBASE_IOS_OAUTH_CLIENT_ID}",
              "client_type": 2,
              "ios_info": {
                "bundle_id": "${FIREBASE_IOS_BUNDLE_ID}"
              }
            }
          ]
        }
      }
    }
  ],
  "configuration_version": "1"
}
EOF

cat > "$IOS_GOOGLE_SERVICE_INFO_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CLIENT_ID</key>
	<string>${FIREBASE_IOS_OAUTH_CLIENT_ID}</string>
	<key>REVERSED_CLIENT_ID</key>
	<string>com.googleusercontent.apps.${FIREBASE_IOS_OAUTH_CLIENT_ID%%.apps.googleusercontent.com}</string>
	<key>ANDROID_CLIENT_ID</key>
	<string>${FIREBASE_ANDROID_OAUTH_CLIENT_ID}</string>
	<key>API_KEY</key>
	<string>${FIREBASE_IOS_API_KEY}</string>
	<key>GCM_SENDER_ID</key>
	<string>${FIREBASE_IOS_MESSAGING_SENDER_ID}</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>${FIREBASE_IOS_BUNDLE_ID}</string>
	<key>PROJECT_ID</key>
	<string>${FIREBASE_IOS_PROJECT_ID}</string>
	<key>STORAGE_BUCKET</key>
	<string>${FIREBASE_IOS_STORAGE_BUCKET}</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<true/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>${FIREBASE_IOS_APP_ID}</string>
</dict>
</plist>
EOF

echo "Synced iOS env config: $IOS_ENV_XCCONFIG"
echo "Synced Android Firebase config: $ANDROID_GOOGLE_SERVICES_JSON"
echo "Synced iOS Firebase config: $IOS_GOOGLE_SERVICE_INFO_PLIST"

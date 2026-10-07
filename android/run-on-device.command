#!/bin/bash
set -euo pipefail

TASK_PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Machine paths belong in the environment or ignored local.properties.
task_local_property() {
    local TASK_VALUE=""
    if [ -f "$TASK_PROJECT_ROOT/android/local.properties" ]; then
        TASK_VALUE="$(sed -n "s/^$1=//p" "$TASK_PROJECT_ROOT/android/local.properties" | head -n 1)"
    fi
    TASK_VALUE="${TASK_VALUE//\\:/:}"
    TASK_VALUE="${TASK_VALUE//\\ / }"
    TASK_VALUE="${TASK_VALUE//\\\\/\\}"
    printf '%s' "$TASK_VALUE"
}

TASK_SDK_ROOT="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$(task_local_property 'sdk\.dir')}}"
TASK_SDK_ROOT="${TASK_SDK_ROOT:-$HOME/Library/Android/sdk}"
TASK_GRADLE_CACHE="${GRADLE_USER_HOME:-$(task_local_property 'taskmanagement\.gradleUserHome')}"
TASK_GRADLE_CACHE="${TASK_GRADLE_CACHE:-$HOME/.gradle}"
TASK_ADB="$TASK_SDK_ROOT/platform-tools/adb"
TASK_DEVICE_ID=""
TASK_SEED_DEMO=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --serial)
            if [ "$#" -lt 2 ]; then echo 'أدخل معرف الهاتف بعد --serial.' >&2; exit 1; fi
            TASK_DEVICE_ID="$2"
            shift 2
            ;;
        --seed-demo) TASK_SEED_DEMO=true; shift ;;
        *) echo "اختيار غير معروف: $1" >&2; exit 1 ;;
    esac
done

if [ ! -x "$TASK_ADB" ]; then
    echo 'أدوات أندرويد غير موجودة في المسار المحدد. اضبط ANDROID_HOME على مجلد SDK الحالي.' >&2
    exit 1
fi
if [ -z "$TASK_DEVICE_ID" ]; then
    TASK_CONNECTED=()
    while IFS= read -r TASK_SERIAL; do
        [ -z "$TASK_SERIAL" ] || TASK_CONNECTED+=("$TASK_SERIAL")
    done < <("$TASK_ADB" devices | awk 'NR > 1 && $2 == "device" {print $1}')
    if [ "${#TASK_CONNECTED[@]}" -ne 1 ]; then
        echo 'وصّل هاتفًا واحدًا وافتحه واسمح باتصال USB debugging. لو فيه أكثر من جهاز، استخدم --serial مع المعرف.' >&2
        "$TASK_ADB" devices -l
        exit 1
    fi
    TASK_DEVICE_ID="${TASK_CONNECTED[0]}"
fi
if [ "$("$TASK_ADB" -s "$TASK_DEVICE_ID" get-state)" != 'device' ]; then
    echo 'الهاتف غير جاهز. افتحه ووافق على اتصال الكمبيوتر.' >&2
    exit 1
fi

echo 'جاري تجهيز نسخة مهامي…'
cd "$TASK_PROJECT_ROOT"
GRADLE_USER_HOME="$TASK_GRADLE_CACHE" ANDROID_HOME="$TASK_SDK_ROOT" \
    ./android/gradlew -p android :app:assembleDebug --quiet --console=plain \
    -Pkotlin.compiler.execution.strategy=in-process

echo 'جاري تثبيت النسخة مع الحفاظ على البيانات…'
"$TASK_ADB" -s "$TASK_DEVICE_ID" install -r "$TASK_PROJECT_ROOT/android/app/build/outputs/apk/debug/app-debug.apk"
echo 'جاري فتح مهامي على الهاتف…'
TASK_LAUNCH_ARGS=()
if [ "$TASK_SEED_DEMO" = true ]; then TASK_LAUNCH_ARGS=(--ez tmPopulateDemo true); fi
"$TASK_ADB" -s "$TASK_DEVICE_ID" shell am start -W --activity-single-top \
    -n com.husseinabozina.taskmanagement/.MainActivity "${TASK_LAUNCH_ARGS[@]}"
echo 'مهامي مفتوح. بعد كده افتحه من أيقونته على الموبايل، حتى من غير الكابل.'

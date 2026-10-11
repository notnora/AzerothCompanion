#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOCAL_ENV_FILE="${PROJECT_ROOT}/.localenvs"

if [[ -f "$LOCAL_ENV_FILE" ]]; then
    source "$LOCAL_ENV_FILE"
fi

ADDON_NAME="AzerothCompanion"
ADDONS_DIR="${WOW_ADDONS_DIR:-}"

if [[ -z "$ADDONS_DIR" ]]; then
    for candidate in \
        "/Applications/World of Warcraft/_classic_era_/Interface/AddOns" \
        "$HOME/Applications/World of Warcraft/_classic_era_/Interface/AddOns"; do
        if [[ -d "$candidate" ]]; then
            ADDONS_DIR="$candidate"
            break
        fi
    done
fi

if [[ -z "$ADDONS_DIR" ]]; then
    printf 'Fant ikke WoW Classic Era AddOns-mappen. Sett WOW_ADDONS_DIR og prøv igjen.\n' >&2
    exit 1
fi

if [[ ! -d "$ADDONS_DIR" ]]; then
    printf 'AddOns-mappen finnes ikke: %s\n' "$ADDONS_DIR" >&2
    exit 1
fi

for source_file in AzerothCompanion.toc AzerothCompanionConstants.lua AzerothCompanionQuestFixtures.lua AzerothCompanionRecommendations.lua AzerothCompanion.lua; do
    if [[ ! -f "${PROJECT_ROOT}/${source_file}" ]]; then
        printf 'Mangler kildefil: %s\n' "${PROJECT_ROOT}/${source_file}" >&2
        exit 1
    fi
done

DESTINATION="${ADDONS_DIR}/${ADDON_NAME}"
mkdir -p "$DESTINATION"
cp -f \
    "${PROJECT_ROOT}/AzerothCompanion.toc" \
    "${PROJECT_ROOT}/AzerothCompanionConstants.lua" \
    "${PROJECT_ROOT}/AzerothCompanionQuestFixtures.lua" \
    "${PROJECT_ROOT}/AzerothCompanionRecommendations.lua" \
    "${PROJECT_ROOT}/AzerothCompanion.lua" \
    "$DESTINATION/"

printf 'Deployet %s til %s\n' "$ADDON_NAME" "$DESTINATION"
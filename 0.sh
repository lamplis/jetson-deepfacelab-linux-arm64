#!/usr/bin/env bash
# Menu principal. L'identifiant 0 n'est pas une étape du pipeline.
#
#   ./0.sh            menu interactif (terminal requis)
#   ./0.sh 6.1.1      lance ce script et quitte avec son code
#
# Un préfixe (6 ou 6.1) affiche les scripts correspondants et n'en lance aucun.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -A GROUP_LABEL=(
  [1.1]="Workspace"
  [2.1]="Images data_src"
  [3.1]="Images data_dst"
  [3.2]="Denoise data_dst"
  [4.1]="Extract faces data_src"
  [4.2]="Util data_src"
  [4.3]="Téléchargements"
  [5.1]="Extract faces data_dst"
  [5.2]="Util data_dst"
  [5.3]="XSeg polygones"
  [5.4]="XSeg modèle"
  [5.5]="XSeg suppression"
  [6.1]="Train SAEHD"
  [6.2]="Train Quick96"
  [6.3]="Train AMP"
  [6.4]="Export DFM"
  [7.1]="Merge SAEHD"
  [7.2]="Merge Quick96"
  [8.1]="Vidéo"
)

IDS=()
FILES=()
NAMES=()

RESOLVE_STATUS=""
RESOLVE_FILE=""
RESOLVE_IDS=()
RESOLVE_NAMES=()

load_scripts() {
  local f base
  local -a found=()
  IDS=()
  FILES=()
  NAMES=()
  shopt -s nullglob
  found=( "$ROOT"/[0-9]*.sh )
  shopt -u nullglob
  if [[ ${#found[@]} -eq 0 ]]; then
    return 0
  fi
  mapfile -t found < <(printf '%s\n' "${found[@]}" | sort -V)
  for f in "${found[@]}"; do
    base="$(basename "$f")"
    if [[ "$base" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)_(.+)\.sh$ ]]; then
      IDS+=("${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}")
      NAMES+=("${BASH_REMATCH[4]}")
      FILES+=("$f")
    fi
  done
}

print_menu() {
  local i group prev="" label
  for i in "${!IDS[@]}"; do
    group="${IDS[$i]%.*}"
    if [[ "$group" != "$prev" ]]; then
      [[ -n "$prev" ]] && echo
      label="${GROUP_LABEL[$group]:-$group}"
      printf '%s  %s\n' "$group" "$label"
      prev="$group"
    fi
    printf '  %s  %s\n' "${IDS[$i]}" "${NAMES[$i]}"
  done
}

print_matches() {
  local i
  for i in "${!RESOLVE_IDS[@]}"; do
    printf '  %s  %s\n' "${RESOLVE_IDS[$i]}" "${RESOLVE_NAMES[$i]}"
  done
}

# 0 exact (RESOLVE_FILE), 1 inconnu, 2 préfixe (RESOLVE_IDS, aucun lancement).
resolve_query() {
  local query="$1"
  local i
  RESOLVE_STATUS=""
  RESOLVE_FILE=""
  RESOLVE_IDS=()
  RESOLVE_NAMES=()
  for i in "${!IDS[@]}"; do
    if [[ "${IDS[$i]}" == "$query" ]]; then
      RESOLVE_STATUS=exact
      RESOLVE_FILE="${FILES[$i]}"
      RESOLVE_IDS=("${IDS[$i]}")
      RESOLVE_NAMES=("${NAMES[$i]}")
      return 0
    fi
  done
  for i in "${!IDS[@]}"; do
    if [[ "${IDS[$i]}" == "$query."* ]]; then
      RESOLVE_IDS+=("${IDS[$i]}")
      RESOLVE_NAMES+=("${NAMES[$i]}")
    fi
  done
  if [[ ${#RESOLVE_IDS[@]} -eq 0 ]]; then
    RESOLVE_STATUS=unknown
    return 1
  fi
  RESOLVE_STATUS=ambiguous
  return 2
}

dispatch_cli() {
  local query="$1"
  resolve_query "$query"
  case $? in
    0)
      bash "$RESOLVE_FILE"
      exit $?
      ;;
    2)
      echo "identifiant ambigu : $query" >&2
      print_matches
      exit 1
      ;;
    *)
      echo "identifiant inconnu : $query" >&2
      exit 1
      ;;
  esac
}

interactive() {
  local query rc
  while true; do
    print_menu
    echo
    if ! read -r -p "Id (vide, q ou quit pour quitter) : " query; then
      echo
      exit 0
    fi
    if [[ -z "$query" || "$query" == "q" || "$query" == "quit" ]]; then
      exit 0
    fi
    resolve_query "$query"
    rc=$?
    if [[ $rc -eq 0 ]]; then
      bash "$RESOLVE_FILE"
      rc=$?
      echo "terminé : $rc"
      echo
      continue
    fi
    if [[ $rc -eq 2 ]]; then
      echo "identifiant ambigu : $query" >&2
      print_matches
      echo
      continue
    fi
    echo "identifiant inconnu : $query" >&2
    echo
  done
}

main() {
  if [[ $# -gt 1 ]]; then
    echo "usage: $(basename "$0") [ID]" >&2
    exit 2
  fi
  load_scripts
  if [[ $# -eq 1 ]]; then
    dispatch_cli "$1"
  fi
  if [[ ! -t 0 ]]; then
    echo "0.sh : menu interactif : un terminal est requis" >&2
    exit 2
  fi
  interactive
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

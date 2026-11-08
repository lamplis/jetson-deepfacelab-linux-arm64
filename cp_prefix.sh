#!/usr/bin/env bash
# Copy images from a folder, prepending a prefix to each filename.
#
#   cp_prefix SRC_DIR [PREFIX] [DEST_DIR]
#
# PREFIX defaults to the source folder name plus "_".
# DEST_DIR defaults to workspace/data_dst/aligned next to this script.
# Only jpg, jpeg, and png files in the top level of SRC_DIR are copied.
#
# Run:
#   ./cp_prefix.sh "/path/to/aligned_xsegBCK"
#   ./cp_prefix.sh "/path/to/aligned_xsegBCK" "aligned_xsegBCK_"
#
# Or load the function into the current shell:
#   source cp_prefix.sh
#   cp_prefix "/path/to/aligned_xsegBCK" "aligned_xsegBCK_"

cp_prefix() {
    local src prefix dest root base count f
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    src="${1:-}"
    if [[ -z "$src" || "$src" == "-h" || "$src" == "--help" ]]; then
        echo "usage: cp_prefix SRC_DIR [PREFIX] [DEST_DIR]" >&2
        return 2
    fi
    if [[ ! -d "$src" ]]; then
        echo "cp_prefix: not a directory: $src" >&2
        return 1
    fi
    prefix="${2:-$(basename "$src")_}"
    dest="${3:-$root/workspace/data_dst/aligned}"
    mkdir -p "$dest"
    count=0
    while IFS= read -r -d '' f; do
        base="$(basename "$f")"
        cp -- "$f" "$dest/${prefix}${base}"
        count=$((count + 1))
    done < <(find "$src" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)
    echo "cp_prefix: $count images -> $dest  (prefix: ${prefix})"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    cp_prefix "$@"
fi

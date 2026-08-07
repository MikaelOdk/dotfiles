#!/bin/bash
set -euo pipefail

_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$_MODULE_DIR")")"
SOURCE_DIR="$DOTFILES_DIR/config/claude"
TARGET_DIR="$HOME/.claude"

# settings.json embeds absolute paths to directory marketplaces, synced from
# whichever machine committed last. Rewrite their home prefix for this machine
# so the same template works everywhere.
rewrite_marketplace_home() {
    jq --arg home "$HOME" \
        '(.extraKnownMarketplaces[]?.source | select(.source == "directory").path) |= sub("^/home/[^/]+"; $home)' \
        "$1"
}

# ~/.claude/settings.json has two authors: this template, and Claude Code
# itself, which writes theme, effortLevel and the accepted-dialog flags at
# runtime. Merge rather than copy, so an install stops wiping those.
install_settings() {
    local template="$SOURCE_DIR/settings.json"
    local target="$TARGET_DIR/settings.json"

    if ! command -v jq &> /dev/null; then
        if [[ -f "$target" ]]; then
            echo "  [WARN] jq not found: kept existing $target unmerged"
        else
            echo "  [WARN] jq not found: marketplace paths keep their original home prefix"
            cp "$template" "$target"
        fi
        return
    fi

    if [[ -f "$target" ]]; then
        # .[0] * .[1]: the template wins on conflicts, keys only the live file
        # has survive. Arrays are replaced wholesale, not concatenated, so the
        # template stays the source of truth for permissions.
        rewrite_marketplace_home "$template" \
            | jq -s '.[0] * .[1]' "$target" - > "$target.tmp"
        mv "$target.tmp" "$target"
        echo "  - Merged template into existing $target"
    else
        rewrite_marketplace_home "$template" > "$target"
        echo "  - Wrote $target"
    fi
}

install_claude_config() {
    echo "Installing Claude Code configuration..."

    mkdir -p "$TARGET_DIR/skills"

    install_settings
    cp "$SOURCE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
    cp "$SOURCE_DIR/statusline.sh" "$TARGET_DIR/statusline.sh"
    chmod +x "$TARGET_DIR/statusline.sh"

    if [[ -d "$SOURCE_DIR/skills" ]]; then
        cp -R "$SOURCE_DIR/skills/." "$TARGET_DIR/skills/"
    fi

    echo "Claude Code configuration installed!"
    echo "  - Settings:  $TARGET_DIR/settings.json"
    echo "  - CLAUDE.md: $TARGET_DIR/CLAUDE.md"
    echo "  - Statusline:$TARGET_DIR/statusline.sh"
    echo "  - Skills:    $TARGET_DIR/skills"
}

install_claude_config

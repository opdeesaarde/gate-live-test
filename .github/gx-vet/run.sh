#!/usr/bin/env bash
# Advice only. Always exits 0, so it can never block a merge.
set -u
OUT=/tmp/gx-vet; mkdir -p "$OUT"
say(){ printf '%s\n' "$1" > "$OUT/c.md"; gh pr comment "$PR" --body-file "$OUT/c.md" >/dev/null || echo "could not post comment"; exit 0; }
NOTE="We could not check this, and it is not your fault."
[ -n "${ANTHROPIC_API_KEY:-}" ] || say "$NOTE The checker has no key. Tell the team lead. Nothing is blocked."
FILES=$(git diff --name-only "$BASE"...HEAD -- . ':(exclude)package-lock.json' ':(exclude)*.lock')
[ -n "$FILES" ] || say "No files to check in this change, apart from package lists. Nothing is blocked."
{ echo "<submission>"; echo "CHANGE:"; git diff "$BASE"...HEAD -- . ':(exclude)package-lock.json' ':(exclude)*.lock'; echo "FULL TEXT OF CHANGED FILES:"
  while IFS= read -r f; do [ -f "$f" ] && { echo "--- $f"; cat "$f"; }; done <<< "$FILES"; echo "</submission>"; } > "$OUT/input.txt"
# Basic screen so obvious keys are never sent. Not a complete secret scan.
if grep -qE 'sk-ant-[A-Za-z0-9_-]{10,}|sb_secret_[A-Za-z0-9_-]{10,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY' "$OUT/input.txt"; then
  say "# Feedback on your change

**Result:** Your change looks like it contains a password or secret key, so we did not check it. Nothing is blocked, but please do not merge this yet.

## What to do next

1. Tell the team lead straight away. The key may need replacing.
2. Copy this into Claude Code: \"My change appears to contain a secret key. Find it, remove it, and read it from a setting instead. Do not show me its value.\"
3. Submit again."
fi
SIZE=$(wc -c < "$OUT/input.txt")
[ "$SIZE" -le 600000 ] || say "$NOTE This change is too big for the checker to read. Ask Claude Code to split it into smaller changes, then submit each one. Nothing is blocked."
call(){ # prompt file, output name
  jq -n --rawfile sys "$1" --rawfile sub "$OUT/input.txt" '{model:"claude-opus-5-5",max_tokens:16000,system:$sys,fallbacks:"default",output_config:{effort:"high"},messages:[{role:"user",content:$sub}]}' > "$OUT/$2.req.json"
  code=$(curl -s -m 280 -o "$OUT/$2.json" -w '%{http_code}' https://api.anthropic.com/v1/messages -H "Content-Type: application/json" -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2026-10-21" -H "anthropic-beta: server-side-fallback-2026-07-01" -d @"$OUT/$2.req.json")
  stop=$(jq -r '.stop_reason // "none"' "$OUT/$2.json" 2>/dev/null)
  if [ "$code" != "200" ] || [ "$stop" != "end_turn" ]; then echo "$2 failed: http $code, stop $stop"; return 1; fi
  jq -r '[.content[]|select(.type=="text")|.text]|join("")' "$OUT/$2.json" > "$OUT/$2.md"; [ -s "$OUT/$2.md" ]
}
call "$PROMPTS/short_prompt.md" short || say "$NOTE The checker did not give an answer ($code). Try submitting again later. Nothing is blocked."
{ cat "$OUT/short.md"; echo
  if call "$PROMPTS/full_prompt.md" full; then
    echo "<details><summary><b>Want more detail?</b> Click for the full report. It may list things the short version leaves out, so read it if your change saves data.</summary>"; echo; cat "$OUT/full.md"; echo; echo "</details>"
  else echo "*The full report could not be produced this time.*"; fi
  echo; echo "<sub>Advice from an automated reviewer. It can be wrong, and it can miss things. A clean result does not prove the change is safe.</sub>"
} > "$OUT/c.md"
head -c 65000 "$OUT/c.md" > "$OUT/c2.md"
gh pr comment "$PR" --body-file "$OUT/c2.md" >/dev/null || echo "could not post comment"
exit 0

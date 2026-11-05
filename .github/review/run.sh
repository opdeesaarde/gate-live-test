set -u
mkdir -p /tmp/review
post(){ gh pr comment "$PR" --body-file "$1" >/dev/null; }
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then echo "We could not check this, and it is not your fault: the checker has no key." > /tmp/review/c.md; post /tmp/review/c.md; exit 0; fi
{ echo "<submission>"; echo "CHANGE:"; git diff "$BASE"...HEAD; echo "FULL TEXT OF CHANGED FILES:"; for f in $(git diff --name-only "$BASE"...HEAD); do [ -f "$f" ] && { echo "--- $f"; cat "$f"; }; done; echo "</submission>"; } > /tmp/review/input.txt
jq -n --rawfile sys /tmp/prompt.md --rawfile sub /tmp/review/input.txt --slurpfile sch /tmp/schema.json \
 '{model:"claude-opus-5-5",max_tokens:16000,system:$sys,fallbacks:"default",output_config:{effort:"high",format:{type:"json_schema",schema:$sch[0]}},messages:[{role:"user",content:$sub}]}' > /tmp/review/req.json
start=$(date +%s)
code=$(curl -s -m 300 -o /tmp/review/resp.json -w '%{http_code}' https://api.anthropic.com/v1/messages -H "Content-Type: application/json" -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2026-10-21" -H "anthropic-beta: server-side-fallback-2026-07-01" -d @/tmp/review/req.json)
secs=$(( $(date +%s)-start ))
stop=$(jq -r '.stop_reason // "none"' /tmp/review/resp.json)
in=$(jq -r '(.usage.input_tokens//0)' /tmp/review/resp.json); out=$(jq -r '(.usage.output_tokens//0)' /tmp/review/resp.json)
jq -n --arg c "$code" --arg s "$secs" --arg st "$stop" --argjson i "$in" --argjson o "$out" '{http:$c,seconds:($s|tonumber),stop:$st,input:$i,output:$o,usd:(($i*4+$o*20)/1000000)}' > /tmp/review/metrics.json
cat /tmp/review/metrics.json
if [ "$code" != "200" ] || [ "$stop" != "end_turn" ]; then { echo "We could not check this, and it is not your fault. The checker returned status $code, stop reason $stop."; jq -r '.error.message // empty' /tmp/review/resp.json | cut -c1-300; } > /tmp/review/c.md; post /tmp/review/c.md; exit 0; fi
jq -r '[.content[]|select(.type=="text")|.text]|join("")' /tmp/review/resp.json > /tmp/review/out.json
if ! jq -e . /tmp/review/out.json >/dev/null; then echo "We could not check this, and it is not your fault: the checker's answer could not be read." > /tmp/review/c.md; post /tmp/review/c.md; exit 0; fi
jq -r --slurpfile m /tmp/review/metrics.json '
 "## Advice on this change (nothing is blocked)\n\n" + .headline + "\n\n" +
 ( if (.findings|length)==0 then "No problems found in this change.\n\n" else
   (.findings|map(
     (if .severity=="must_fix" then "### Fix before this goes live" elif .severity=="should_fix" then "### Worth fixing" else "### A note" end) +
     "\n**What is wrong:** " + .what_is_wrong + "\n\n**Where:** " + .where + "\n\n**Why it matters:** " + .why_a_reader_cares +
     "\n\n**Ask Claude:** \"" + .ask_claude + "\"\n\n*How sure: " + (.how_sure|gsub("_";" ")) + "*\n") | join("\n")) + "\n" end ) +
 "**What was checked:** " + (.checked|join("; ")) + "\n\n**What was not checked:** " + (.not_checked|join("; ")) +
 "\n\n<sub>" + ($m[0].seconds|tostring) + " seconds, $" + ($m[0].usd*1000|round/1000|tostring) + "</sub>\n"' /tmp/review/out.json > /tmp/review/c.md
post /tmp/review/c.md

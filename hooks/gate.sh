#!/usr/bin/env bash
#
# no-numb gate — runs on the Claude Code Stop hook.
#
# Job: a "doorbell," nothing more. Did Claude edit a file this run, and have we
# not already quizzed for it? If so, block the stop and tell Claude to run the
# quiz-me skill. ALL judgement (what/whether/how to quiz) lives in the skill.
#
# Requires: jq.  See SPEC.md §5.3 for the design and the stop_hook_active trap.

input="$(cat)"

# Helper: read a field from the hook's stdin JSON. Falls back to empty on error.
field() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

# 1) Already quizzed this cycle → let Claude stop.
#    When we block, the quiz runs as a CONTINUATION of the same run, so the
#    edits are still "this run" when Claude tries to stop again. Without this
#    guard the hook would re-block forever (pass quiz → re-quiz → forever).
#    Claude Code sets stop_hook_active=true on that continuation.
[ "$(field '.stop_hook_active // false')" = "true" ] && exit 0

# 2) Off switch. Config lives outside any repo so it survives pulls/reinstalls.
#    Note: test `.enabled == false` explicitly — jq's `//` treats false as "use
#    default", so `.enabled // true` would wrongly read false as true. Missing
#    file or key → enabled (default on).
config="${HOME}/.no-numb/config.json"
if [ -f "$config" ] && [ "$(jq -r '.enabled == false' "$config" 2>/dev/null)" = "true" ]; then
  exit 0
fi

# 3) Doorbell: did Claude Edit/Write/MultiEdit/NotebookEdit any file since the
#    user's last prompt (i.e. during this run)? No transcript → fail open (no
#    quiz), because trapping the user on a parse error is worse than missing one.
transcript="$(field '.transcript_path // empty')"
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

edited="$(jq -s '
  # Content can be nested as .message.content (common) or .content; handle both.
  def blocks: (.message.content // .content // []);

  # A genuine user prompt: a user line carrying real text (string content, or an
  # array with a text block) — as opposed to a user line that is only tool_result.
  def is_prompt:
    .type == "user"
    and (
      ((blocks | type) == "string" and (blocks | length) > 0)
      or ((blocks | type) == "array" and (blocks | any(.[]?; .type == "text")))
    );

  # An assistant turn that edited a file.
  def is_edit:
    .type == "assistant"
    and (blocks | type) == "array"
    and (blocks | any(.[]?;
          .type == "tool_use"
          and (.name == "Edit" or .name == "Write"
               or .name == "MultiEdit" or .name == "NotebookEdit")));

  . as $arr
  | (([ range(0; ($arr | length)) | select($arr[.] | is_prompt) ] | last) // -1) as $start
  | [ $arr[($start + 1):][] | select(is_edit) ] | length > 0
' "$transcript" 2>/dev/null || echo false)"

if [ "$edited" = "true" ]; then
  jq -n '{
    decision: "block",
    reason: ("You edited files this turn. Before finishing, run the no-numb quiz-me skill: "
      + "quiz the user with multiple-choice questions via AskUserQuestion (honoring the depth "
      + "in ~/.no-numb/config.json) on what you just did, and do not end your turn until they pass. "
      + "If the change was genuinely cosmetic (formatting, a rename, a color, a typo), say so in "
      + "one line instead of quizzing.")
  }'
fi

exit 0

---
name: quiz-me
description: Use right after writing or editing code or files for the user — before ending your turn — to quiz them on what was just built and confirm they actually understand it. Also triggers on "quiz me", "test my understanding", "check what I learned", "comprehension check", or recovering the understanding that vaporizes when you orchestrate an agent instead of authoring the code yourself.
---

# No-Numb: quiz the user on what was just built

## Overview

After you write code for someone, they usually understand the result at a high level — what it does, its inputs and outputs — but not the internals or the *why*. That understanding "vaporizes." This skill has you administer a short comprehension quiz on **what you just did this turn**, so the understanding sticks. Being tested is itself the learning (retrieval practice); the quiz is not just a check.

**Core principle:** quiz what *this turn* produced, from your own memory of what you just did — not generic trivia, not the whole codebase, not what the app does at a high level.

## When to run

- Right after a turn in which you edited or wrote files, before finishing.
- When the user runs `/no-numb:quiz-me`.
- When the no-numb Stop hook blocks your turn and asks you to quiz.

## Step 1 — Is it worth quizzing?

Look at what you changed this turn. **Bias toward quizzing.** Only skip when the change is *genuinely cosmetic*:

- formatting / whitespace, a variable rename, a CSS color tweak, a typo fix, a version bump.

Everything else → quiz. **When in doubt, quiz.** If you do skip, say so in one line and stop — don't quiz on nothing.

## Step 2 — Read the settings

Read `~/.no-numb/config.json` for `depth` (`"standard"` or `"deep"`; default to `"standard"` if the file or key is missing). Note whether this was a **code** change or a **non-code** change (docs/prose/config) — it changes how the depth dial applies (Step 3).

## Step 3 — Generate the questions

Scale the **number** of questions to the size and complexity of the change: a one-line fix → 1–2; a new module → more. Don't pad to hit a count.

Depth controls **how you ask, not the topic**. The single test:

> **Do you need to read the code to answer it? Yes → that's a deep question. No → that's a standard question.**

**`standard` (default) — answerable WITHOUT opening a file.**
The user should be able to answer from understanding the *decisions*. Do **not** reference specific files, lines, or function names.
- Good: *"Why does X break if that guard is removed?"*, *"Why this approach over the obvious alternative?"*, *"What's the failure mode of this path?"*, *"What happens in the case where \<condition>?"*

**`deep` — only answerable BY reading the code.**
The user must go look at the implementation. **Always point them to where to look** (file + function/region), so the time goes into reading and reasoning, not hunting. Favor reasoning over recall.
- Good: *"In the doorbell check in `gate.sh`, what kind of edit would slip past it?"*, *"Trace `value` through the branches in `parseConfig` — what comes back when the input is empty?"*
- Bad (recall trivia): *"What's the third argument to this call?"*, *"What does line 12 return?"*

**Non-code changes** (docs/prose): the read-the-code test doesn't apply — ask about *what changed* (*"what does the new section actually commit us to?"*) and treat depth as a difficulty knob (deep = harder/more specific, standard = lighter/higher-level). Config files are code-like enough that deep works normally.

**Stay below the awareness line (both modes):** never ask *"what does this app do"* or *"what are its inputs and outputs."* That's the high-level understanding the user already has — testing it teaches nothing. Aim at the internals and the *why* — the part that vaporizes.

## Step 4 — Deliver as multiple choice, one at a time

Deliver with `AskUserQuestion`, **one question per call**. Write **plausible distractors**: the wrong options must be the misconceptions someone would actually hold if they didn't understand this code. Obvious-dummy options turn it back into trivia and let them pass by elimination.

> Multiple choice is required, not a style preference. `AskUserQuestion` is a tool call, so your turn stays alive and the gate can hold. A plain-text question would force you to end your turn and wait for a reply — which releases the gate. Do not switch to prose questions during a gated quiz. (The "Other" free-text box is fine for the rare question that needs a typed answer, since it stays inside the tool call.)

## Step 5 — Grade and explain

After each answer: if correct, confirm in a sentence. If wrong, show the correct option **and explain *why*** — the specific low-level detail they missed. This explanation is where the learning actually lands, so make it real, not a restatement.

## Step 6 — Retake on any miss

Any wrong answer means the user retakes the **full** quiz. Regenerate it with light rewording and reordering so they can't just memorize the answer key. **Stay in this turn and keep going until they pass** — do not end your turn, summarize, or move on to other work until every answer is correct (or the user deliberately interrupts). On a pass, you're done; just conclude normally.

## Quick reference

| Mode | The test | References specific files/lines? | Example |
|---|---|---|---|
| `standard` | answer it *without* reading code | **no** | "why would this deadlock if you swapped the lock order?" |
| `deep` | must *read* the code to answer | **yes** — point them there | "in `parseConfig`, what input makes it return null?" |

## Common mistakes

- **Quizzing the whole repo.** Only quiz what *this turn* changed.
- **Trivia distractors.** "What does this return" with three silly options isn't comprehension. Make the wrong answers tempting.
- **Drifting too high.** "What does the app do" tests what they didn't lose. Stay on internals and *why*.
- **Standard that references code, or deep that doesn't point to it.** standard = no file/line references; deep = always say where to look.
- **Switching to prose in a gated turn.** It ends your turn and releases the gate. Keep it `AskUserQuestion` multiple choice.
- **Skipping too eagerly.** Only *genuinely cosmetic* changes skip. When unsure, quiz.

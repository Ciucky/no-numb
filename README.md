# No-Numb

**Build with Claude Code without your brain going numb.** No-Numb quizzes you on the code Claude just wrote — and, by default, blocks the session from continuing until you pass.

> The middle ground: built fast like an agent, understood like you wrote it yourself.

---

## The problem

When you build with an AI agent you operate at high altitude — you set the goal, the agent makes the thousand low-level decisions. You ship working software you can describe at a high level, but if someone asked you to explain the internals, the data flow, or *why* a particular approach was chosen, you couldn't. The learning that used to be a *side effect* of writing code is now optional, and the path of least resistance skips it.

The names for this are dry but real: *cognitive offloading*, *automation complacency*, *skill atrophy*. We just call the feeling **numb**.

No-Numb makes the good habit — actually understanding what got built — the **default path** instead of the disciplined-person path. A skill can be ignored; a hook enforces. And being tested is itself one of the most reliable ways to make knowledge stick (the *testing effect*), so the friction isn't a tax on the feature — the friction **is** the feature.

## How it works

1. You build with Claude Code as normal.
2. When Claude finishes a turn in which it **edited or wrote a file**, a `Stop` hook intercepts and has Claude generate a short comprehension quiz about **what it just did this turn** — drawn from its own context, not generic trivia.
3. Questions arrive one at a time as **multiple choice** (Claude Code's native `AskUserQuestion` UI).
4. Get one wrong → it shows the right answer **and explains why**, then you retake the full quiz (lightly reworded so you can't memorize the key).
5. Until you pass, the session won't move on. The only way past without passing is a deliberate interrupt (Esc) — skipping is possible, but it's a *choice*, not the easy path.

Pure conversation turns (no file edits) are never quizzed. Genuinely cosmetic changes (a rename, a color tweak, a typo) are skipped by Claude's judgment.

## The two dials

That's the entire config surface — two keys in `~/.no-numb/config.json`:

```json
{
  "enabled": true,
  "depth": "standard"
}
```

**`enabled`** — `true` (default) or `false`. `true` is the forcing function; `false` does nothing. If you install a tool whose whole purpose is the forcing function, you want it on — so it defaults on. (The file is optional; with no file at all, the defaults apply.)

**`depth`** — `"standard"` (default) or `"deep"`. One black-and-white test decides which a question is:

> **Do you need to read the code to answer it? Yes → deep. No → standard.**

- **`standard`** — questions you can answer from understanding the *decisions* (why this breaks, why this approach, what the failure mode is), **without opening a file**.
- **`deep`** — questions you can only answer by **going and reading the code** (it tells you where to look). More granular, but still reasoning over rote recall.

Neither level tests "what does this app do" — that's the high-level understanding you *don't* lose. Both aim below the awareness line, at the part that vaporizes.

Want a quiz without the gate? Run **`/no-numb:quiz-me`** any time for a voluntary self-check.

## Install

**Prerequisites:** Claude Code with plugin support, and [`jq`](https://jqlang.github.io/jq/) on your PATH (the hook uses it).

```
/plugin marketplace add Ciucky/no-numb
/plugin install no-numb@no-numb
```

Or, to try it locally from a clone:

```
/plugin marketplace add /path/to/no-numb
/plugin install no-numb@no-numb
```

No-Numb creates `~/.no-numb/config.json` with these defaults on first run, so there's always a file to edit. Change `"enabled"` to `false` to pause it, or `"depth"` to `"deep"` for harder questions. It lives in your home directory (not the plugin folder) so your settings survive plugin updates, and an existing file is never overwritten.

## Honest notes

- **It costs extra tokens.** No-Numb deliberately prompts Claude to generate and grade a quiz after editing turns — that spend *is* the learning loop. The `enabled: false` switch is your affordability valve for deadline days; `/no-numb:quiz-me` is the on-demand alternative.
- **It's a forcing function, not DRM.** The hook guarantees a quiz *starts*; the skill keeps going until you pass. You can always hit Esc, disable the plugin, or interrupt. The point is that learning is on *by default* and skipping is a deliberate act.
- **Plugins run code.** No-Numb ships a Bash hook (`hooks/gate.sh`) and a skill. Read the source before you install — it's short, and reviewing plugins before trusting them is the right habit.

## License

MIT.

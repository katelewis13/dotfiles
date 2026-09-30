---
name: coding-style
description: Coding style preferences for C# and TypeScript. Consult this whenever writing, reviewing, or refactoring C# or TypeScript code to ensure it matches these preferences. Also trigger when the user corrects a style choice or says they prefer X over Y — propose capturing the preference before saving it.
---

# Coding Style

## Philosophy

Code should explain itself through naming and structure. The reader should be able to follow the logic without narration. Always aim to keep code in a better state than where you found it and keep readability at the forefront of every decision. 

## Preferences

**Control flow**

- Prefer early returns and guard clauses over wrapping logic in conditionals
- When a condition guards most of a method body, invert it and return/throw early
- Minimise nesting depth — flat is easier to follow than deeply indented
- When the same decision is made twice — once to pick a value, once to describe or
  classify it — collapse it into branches that return both together. Re-deriving the
  same conclusion from the inputs lets the two answers drift, and forces the reader to
  simulate both to check they agree

  A fallback chain paired with a flag re-derived from the same inputs is the usual tell:

  ```ts
  // Two derivations of one decision. Nothing keeps them in step.
  const destination = returnUrl ?? referrerUrl ?? defaultUrl;
  const cameFromReferrer = Boolean(returnUrl || referrerUrl);
  ```

  Each branch already knows both answers, so let it say both:

  ```ts
  if (returnUrl) return { destination: returnUrl, cameFromReferrer: true };
  if (referrerUrl) return { destination: referrerUrl, cameFromReferrer: true };

  return { destination: defaultUrl, cameFromReferrer: false };
  ```

**Comments**

- Consult the `coding-style-comments` skill whenever writing or reviewing comments

**Error handling**

- Never catch, log, and rethrow. If you can't handle an exception, let it propagate — the log line duplicates what the stack trace already carries
- A catch block must change behaviour: return a value, translate the exception, or recover. If it does none of those, delete it
- Prefer `catch (SpecificException e) when (<filter>)` over a broad catch, so unrelated failures are never intercepted

**Surrounding code**

- Never lower code quality, or drop one of these preferences, to match nearby code. Bad existing code is not a precedent
- If tempted to match a local pattern that conflicts with these preferences, ASK first — name the conflict and which preference it breaks. Don't resolve it silently in either direction
- Leaving pre-existing bad code untouched is normal scope discipline, not a compromise — but offer it as a follow-up rather than assuming it should stay

**Structure and indirection**

- A variable that doesn't vary isn't configuration. If a value is identical across every environment or caller, inline it where it's used once, or make it a local/constant if it's used often — don't keep a config knob for something that never changes
- Prefer inlining single-use indirection over naming it. A name earns its place by being reused, or by explaining something the literal doesn't

**Terraform**

- Consult the `coding-style-terraform` skill for Terraform — file organisation, modules, variables, state and refactoring

## Capturing new preferences

When the user corrects a style choice or expresses a preference during a session, say:

> "I'd capture this as: [exact wording]. Want me to add it to your coding style skill?"

Wait for confirmation before editing this file. Always show the exact wording before asking.

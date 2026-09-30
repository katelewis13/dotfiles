---
name: coding-style-comments
description: Preferences for code comments in any language. Consult this whenever writing, reviewing, or refactoring comments, docstrings or doc blocks — deciding whether a comment should exist, what it should say, or how long it should be. Also trigger when the user corrects a comment or says they prefer X over Y — propose capturing the preference before saving it.
---

# Coding Style — Comments

## Philosophy

Treat every comment as a smell until it is justified. The default verdict is delete.

Code should explain itself through naming and structure. If a comment seems necessary to explain what the code does, the code is bad — fix the code. The comment goes either way.

A handful of comments do earn their place, and they all have the same shape: they carry something the code cannot carry, usually because it lives outside the code.

## Before writing a comment

Try to remove the need for it first — rename the symbol, extract the logic, tighten the type, restructure the flow. Only when that fails does a comment get considered, and then only if it matches one of the categories below. Prefer deleting a weak comment over shortening it.

## The only comments that earn their place

1. **An external constraint** — behaviour forced on you by something you don't control: a vendor API, a protocol, a platform bug, an upstream library. Cite the source where there is one
2. **A business rule or requirement whose source sits outside the code** — a regulation, a contract with another team, a migration cut-off. Name the source; don't restate the rule. "Customers migrated before 2019 stay on the old billing schedule (MKP-1234)" earns its place because the rule is arbitrary and the code can only show the branch. `// tax is 15%` doesn't — that's a badly named constant
3. **Why something isn't there** — "no retry here, the endpoint isn't idempotent." An omission can't be named or structured, so this is the one case renaming genuinely cannot fix
4. **A tooling directive** — a lint suppression, `prettier-ignore`, a generated-file marker. Only where the rule being suppressed is genuinely wrong, not merely inconvenient
5. **A public API contract, limited to the part the signature can't carry** — units, nullability, thrown exceptions, side effects, valid ranges. A doc comment that restates the signature belongs on the delete list

## Delete on sight

- Narration — any comment describing what the code does
- Banner and divider blocks, and section headers
- Commented-out code. Git has it
- TODOs with no ticket
- Attribution and changelog notes — "added by X for MKP-1234". Git has that too
- The ticket number of the change that introduced the code. Git records that. The comment can still state the rule
- Doc comments that restate the signature
- "Don't remove this", "important", "risky", with no verifiable reason behind it

## Before deleting

If a comment claims a constraint you can't confirm from the surrounding code, check it — trace the call, look at the dependency, read the ticket. Then:

- Confirmed false or stale — delete it
- Confirmed true — keep it
- Can't be checked from here, because it names a system you have no access to — leave it and say so in your summary

Never delete a claim about an external constraint just because you couldn't reach the thing it names.

## Writing the ones that survive

- One or two sentences, MAX. If the _why_ won't fit, that's evidence the code is unclear — fix the code.
- What never belongs is the debate that produced the decision, or a record of alternatives considered
- Prefer XML doc comments (`///`) over `//` line comments when documenting properties or fields — they surface in IntelliSense; reserve `//` for inline notes on non-obvious logic
- A `<summary>` says what the thing is or does. It's what shows on hover, so it has to answer that first. Rationale and caveats belong in `<remarks>`, or in the `<param>`, `<returns>` or `<exception>` tag they describe — unless the constraint is what defines the thing (idempotent, thread-safe), which belongs in the summary itself. A summary that only says what something doesn't do leaves the reader still not knowing what it is
- Write every comment as though you cannot see any other implementation. Describe only the file the comment sits in — never a sibling's behaviour or a collaborator's internals. Nobody changing that other file has a reason to come and update this comment, so it goes stale unnoticed and the next reader believes it. Document the fact where it's true, and if it matters here, assert it in a test
- When a comment exists to stop someone changing the code, write the test that fails when they do instead. If no test can tell the two versions apart, there was no constraint to protect

## Capturing new preferences

When the user corrects a comment style choice or expresses a preference during a session, say:

> "I'd capture this as: [exact wording]. Want me to add it to your comments style skill?"

Wait for confirmation before editing this file. Always show the exact wording before asking.

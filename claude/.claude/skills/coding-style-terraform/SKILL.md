---
name: coding-style-terraform
description: Coding style preferences for Terraform. Consult this whenever writing, reviewing, or refactoring Terraform — .tf, .tfvars, .tftpl files, modules, HCL config — to ensure it matches these preferences. Also trigger when the user corrects a Terraform style choice or says they prefer X over Y — propose capturing the preference before saving it.
---

# Coding Style — Terraform

## Philosophy

Config should explain itself through naming and structure. The reader should be able to follow what gets created without narration.

Terraform is declarative, and closer to documentation than to code. Every resource should be readable as written, bar the few values that are environment-specific, so you can tell what's deployed without running anything. It isn't meant to be reusable or dynamic most of the time, and each layer of abstraction you add buys indirection and somewhere new for things to go catastrophically wrong.

Keep indirection minimal. Chasing a value through six files to find out what it actually is makes config harder to read than a slightly repetitive literal would. Names matter a lot: a resource, variable or local that's named well saves the reader from looking anywhere else.

Always drive Terraform forwards. Changes that a `plan` and `apply` can carry out — `import`, `moved` and `removed` blocks — are preferred over CLI state commands or a separate destroy pipeline, because they're visible in the plan and reviewable in the PR.

## Comments

- Consult the `coding-style-comments` skill whenever writing or reviewing comments — the rules there apply to Terraform as they do anywhere else

## Variables and indirection

- A variable that doesn't vary isn't configuration. Variables are for values that differ between environments, or that are secret. If a value is identical across every environment or caller, inline it where it's used once, or make it a `local` if it's used often — don't keep a variable for something that never changes
- Prefer inlining single-use indirection over naming it. A `local` earns its place by being reused, or by explaining something the literal doesn't
- Give every variable a `type`. Add a `description` only where the name doesn't already carry the meaning
- `dynamic` blocks, and `for_each`/`count` over anything but a plain literal map, should be rare. Before adding one, check whether writing the resources out is simpler to read — usually it is. `dynamic` is the worst of the three, since the resulting resource shape isn't visible anywhere in the config

## Modules

- Modules are for enforced sameness, never for tidiness. Reach for one when several resources must always have identical configuration — a standard S3 bucket with the same security policies everywhere — because a module is what makes that sameness mandatory instead of aspirational. Two copies of something is not on its own a reason for a module
- No single-use modules. If a module has exactly one consumer, inline it into the root and delete the `modules/` tree. Don't copy the pattern from a reference repo just because it's there
- Never declare a `provider` block inside a module — it's deprecated, and it's a sign the module shouldn't exist

## File organisation

- Split _resources_ into separate files by type — one file per logical resource group, so a reader can find a thing by its kind
- Group the supporting wiring — providers, backend, locals, data sources — into a single file when each part is small. Don't carve out a file to hold one local or a seven-line backend block
- Judge by size, not by category: a concern gets its own file once it is substantial enough to stand alone
- Group the root wiring in `main.tf` in this order: backend, providers, locals, data sources

## State and refactoring

- Never hand-edit the state file. Every state change goes through an `import`, `moved` or `removed` block that CI applies
- When a refactor renames resource addresses, use `moved {}` blocks rather than `terraform state mv` — they're declarative, visible in the plan, reviewable in the PR, and applied by CI automatically. Leave them in place afterwards unless asked to remove them; they document where the resource used to live
- To bring an existing object under management, use an `import {}` block rather than `terraform import` — same reasons. Leave the block in place afterwards unless asked to remove it; it documents that the object predates the config and where it came from
- To take a resource out of config, use a `removed {}` block rather than `terraform state rm`. This includes when the object should actually be destroyed — set `lifecycle { destroy = true }` and let the plan show it. Use `destroy = false` only when the object should survive untracked. Leave the block in place afterwards unless asked to remove it; it documents that the resource was deliberately taken out
- Never run `terraform destroy`, or any other CLI command that changes state directly. Every state change goes through config that CI applies, so it shows up in a plan and a PR
- Verify a refactor with a plan showing `0 to add, 0 to destroy` before committing it

## Surrounding code

- Never lower quality, or drop one of these preferences, to match nearby config. Bad existing Terraform is not a precedent
- If tempted to match a local pattern that conflicts with these preferences, ASK first — name the conflict and which preference it breaks. Don't resolve it silently in either direction
- Leaving pre-existing bad config untouched is normal scope discipline, not a compromise — but offer it as a follow-up rather than assuming it should stay

## Capturing new preferences

When the user corrects a Terraform style choice or expresses a preference during a session, say:

> "I'd capture this as: [exact wording]. Want me to add it to your Terraform coding style skill?"

Wait for confirmation before editing this file. Always show the exact wording before asking.

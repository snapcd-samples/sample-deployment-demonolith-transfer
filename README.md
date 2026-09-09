# sample-deployment-demonolith-transfer

This sample picks up where [sample-deployment-demonolith](https://github.com/snapcd-samples/sample-deployment-demonolith) ends: the monolith is long split, and what remains is a landscape of living roots — `networking`, `cluster`, `database`, `app` — each with its own remote state, plus a `snapcd` root wiring them into Snap CD. Months later you notice the split put two things in the wrong place: a DNS zone and a backup suffix grew up in `app` but belong in `networking` and `database`. Moving them is a **transfer**, not a split — every root involved already exists, already has state, and keeps living afterwards — and that is what [demonolith](https://github.com/schrieksoft/demonolith)'s `transfer` family does: the code move and the state move, both proven to change nothing, with the Snap CD wiring updated along the way.

[sample-deployment-transfer](https://github.com/snapcd-samples/sample-deployment-transfer) is the minimal standalone version of the same journey; this sample is the full one — the landscape from the split, the Snap CD integration, and the CI lanes a team would run.

No cloud account is needed: the "infrastructure" is simulated with the credential-free `random` provider, and the remote state store is a local MinIO container standing in for S3.

## The world

- **`app`** — the source root. It owns the release and endpoint names, but four of its blocks carry `# @demono:move <dir>` comments naming where they belong, as directories relative to the app root: `random_pet.dns_zone` and `random_uuid.dns_zone_id` to `../networking`, `random_id.backup_suffix` to `../database`.
- **`networking`**, **`database`** — the receivers: living roots with their own resources and their own states, which the moved blocks join.
- **`cluster`** — a bystander. Part of the landscape, wired into Snap CD, untouched by the transfer.
- **`snapcd`** — one `snapcd_module` per root, the shape demonolith's bootstrap generates. Applying it needs a running Snap CD server (the closing section); the transfer updates its code either way.

Three knots make this transfer worth watching. `app`'s `endpoint_name` still reads the moved `dns_zone` — a dependency that now crosses the root boundary, so the transfer rewrites `app` in place to consume it as a variable, gives `networking` the matching `output`, and appends the `snapcd_module_input_from_output` to `roots/snapcd/main.tf` so Snap CD passes the value at runtime. The moved `backup_suffix` has a `depends_on` on the moved `dns_zone_id` — an ordering-only dependency between the two receivers, which becomes a `snapcd_depends_on_module`. And `backup_suffix` reads a `local` that reads a `variable`: both declarations travel with it into `database` (a name the receiver already declared would be a refusal — merging declarations is a human decision, not the tool's).

## The journey

Prerequisites: demonolith 0.5.0 or newer on the PATH, Docker, and OpenTofu.

```
./step0_store.sh      # MinIO up, bucket created (reuses a store already on :9000)
./step1_env.sh        # seed .env with the store credentials
./step2_baseline.sh   # apply the four roots; each must plan clean
./step3_refactor.sh   # the CODE move: demonolith transfer refactor -y --root-dir roots/app
./step4_migrate.sh    # the STATE move: demonolith transfer migrate --all -y --engine tofu --root-dir roots/app
```

Step 3 is `transfer refactor` (map → run → diff): the map records what moves where and the wiring the move creates, the run edits the roots' own files — blocks out of `app/main.tf` (its reference to the moved zone rewritten into a variable), into the receivers' `main.tf`/`variables.tf`/`outputs.tf`, the Snap CD wiring into `roots/snapcd/main.tf` — and a byte-identical copy of the finalized map lands in every touched root. That copy is the point: each root can now gate its own files with a bare `transfer refactor diff` run against it, nothing else checked out, and the map file's checksum is the transfer's identity everywhere. In a real setup this is a normal PR (or one PR per repo, each carrying its slice and the map); nothing has touched any state.

Step 4 is `transfer migrate` (map → prove → run → verify), and it works **one root at a time**: every step pulls, proves, or writes exactly one root's state, with only that root's checkout and credentials. What must cross between roots travels as files in each root's `.demono-transfer/` — the moved resources' state fragment (from `app`'s map step to its receiver's), producer output values (`networking`'s threaded into `app`'s proof, exactly what Snap CD does at runtime), and run receipts (the receivers' to `app`, whose own state is refused its write until every receiver's is receipted). Because this sample keeps all the roots in one checkout, `--all` lets demonolith run every root's part itself, in dependency order; roots on separate machines each run their own side and pass the files between them. A crashed run is retried by just re-running: completed roots skip, the rest write.

## The window to respect

Between step 3 landing and step 4 completing, `app`, `networking` and `database` plan dirty — `app` would destroy the moved resources, the receivers would duplicate them. In a real setup those roots' pipelines freeze the moment the code move merges, the state move runs immediately after, and `transfer migrate verify` reopens the world. Keep the window minutes long, not days. `cluster` never enters it.

## The same story in CI

[`.github/workflows/transfer.yml`](.github/workflows/transfer.yml) runs the journey as the three lanes a real team would use; for illustration it targets the `pr-to-me` demo branch and nothing runs on `main`. The **slice-diff** lane is the standing gate on every PR: one matrix leg per touched root, each running a bare `transfer refactor diff` against that root and its own map copy — in a multi-repo landscape each leg is a different repo's whole gate. The **migrate-rehearse** lane builds the pre-transfer world from the PR's base commit, switches to the PR's code, and runs `migrate map` + `prove` — read-only, so a rejected PR leaves the world untouched. The **migrate** lane is `workflow_dispatch` only: a deliberate act taken once, after the merge, during the freeze; demonolith's own pins and receipts make re-running it safe and running it stale impossible.

## Handing the wiring to Snap CD

The transfer left `roots/snapcd/main.tf` with the new `snapcd_module_input_from_output` and `snapcd_depends_on_module` blocks — the runtime form of the value the proofs threaded locally. To see it live, run a Snap CD server (for example [snapcd-deployment-docker](https://github.com/schrieksoft/snapcd/tree/main/serving/snapcd-deployment-docker), whose runner reaches this sample's store at `http://localhost:9000`), push this repo, and apply the root:

```
tofu -chdir=roots/snapcd init
tofu -chdir=roots/snapcd apply -var source_url=<your fork's git URL>
```

Snap CD then plans all four modules — producers before consumers, `networking`'s zone passed into `app`'s new input — and every one plans to zero changes: the same verdict `transfer migrate verify` reached, now delivered by the system that owns the ordering from here on.

## After

The moved resources have exactly one home: `networking`'s and `database`'s states gained them, `app`'s state lost them, and no resource was ever destroyed or recreated. `app`'s one new need — a value for its input — is met by Snap CD at runtime, which is precisely what the added wiring declares.

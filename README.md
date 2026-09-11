# sample-deployment-demonolith-transfer

This sample picks up where [sample-deployment-demonolith](https://github.com/snapcd-samples/sample-deployment-demonolith) ends: the monolith is long split, and what remains is a landscape of living roots - `networking`, `cluster`, `database`, `app` - each with its own remote state, plus a `snapcd` root wiring them into Snap CD. Months later you notice the split put two things in the wrong place: a DNS zone and a backup suffix grew up in `app` but belong in `networking` and `database`. Moving them is a **transfer**, not a split - every root involved already exists, already has state, and keeps living afterwards - and that is what [demonolith](https://github.com/schrieksoft/demonolith)'s `transfer` commands do: the code move and the state move, both proven to change nothing, with the Snap CD wiring updated along the way.

A transfer has exactly one receiver, so this is two transfers, run one after the other - which is the point: each one is small, proven, and landed on its own.

No cloud account is needed: the "infrastructure" is simulated with the credential-free `random` provider, and the remote state store is a local MinIO container standing in for S3.

## The world

- **`app`** - the source root. It owns the release and endpoint names; the two DNS blocks are marked with a bare `# @demono:transfer` comment, ready for the first transfer. The backup suffix is not marked yet - it gets its comment in step 5, when its transfer starts.
- **`networking`**, **`database`** - the receivers, one per transfer: living roots with their own resources and their own states.
- **`cluster`** - a bystander. Part of the landscape, wired into Snap CD, untouched by both transfers.
- **`snapcd`** - one `snapcd_module` per root, the shape demonolith's bootstrap generates. Applying it needs a running Snap CD server (the closing section); the first transfer updates its code either way.

Three knots make the journey worth watching. `app`'s `endpoint_name` still reads the moved `dns_zone` - a dependency that now crosses the root boundary, so the transfer rewrites `app` in place to consume it as a variable, gives `networking` the matching `output`, and appends the `snapcd_module_input_from_output` to `roots/snapcd/main.tf` so Snap CD passes the value at runtime. `backup_suffix` has a `depends_on` on the moved `dns_zone_id` - the entry is dropped from the block and becomes a `snapcd_depends_on_module` instead. And in the second transfer, `backup_suffix` reads a `local` that reads a `variable`: both declarations travel with it into `database` (a name the receiver already declared would be a refusal - merging declarations is a human decision, not the tool's).

## The journey

Prerequisites: a demonolith with the one-receiver transfer commands on the PATH, Docker, and OpenTofu.

```
./step0_store.sh      # MinIO up, bucket created (reuses a store already on :9000)
./step1_env.sh        # seed .env with the store credentials
./step2_baseline.sh   # apply the four roots; each must plan clean
./step3_refactor.sh   # transfer 1, the CODE move:  transfer refactor -y --transfer-target ../networking
./step4_migrate.sh    # transfer 1, the STATE move: transfer migrate --both -y --engine tofu
./step5_refactor2.sh  # transfer 2, the CODE move:  mark backup_suffix, then --transfer-target ../database
./step4_migrate.sh    # transfer 2, the STATE move: the same command moves whichever transfer is mapped
```

Step 3 is `transfer refactor` (map → run → diff): the map records what moves and the wiring the move creates, the run edits the roots' own files - blocks out of `app/main.tf` (its reference to the moved zone rewritten into a variable), into `networking`'s `main.tf`/`variables.tf`/`outputs.tf`, the Snap CD wiring into `roots/snapcd/main.tf` - and a byte-identical copy of the finalized map lands in every touched root. That copy is the point: each root can now gate its own files with a bare `transfer refactor diff` run against it, nothing else checked out, and the map file's checksum is the transfer's identity everywhere. In a real setup this is a normal PR (or one PR per repo, each carrying its slice and the map); nothing has touched any state.

Step 4 is `transfer migrate` (map → prove → run → verify), and it works **one root at a time**: every step pulls, proves, or writes exactly one root's state, with only that root's checkout and credentials. What must cross between the roots travels as files in each root's `.demono-transfer/` - the moved resources' state fragment (from `app`'s map step to the receiver's), output values (`networking`'s threaded into `app`'s proof, exactly what Snap CD does at runtime), and the receiver's run receipt, without which `app`'s own state is refused its write. Because this sample keeps the roots in one checkout, `--both` lets demonolith run both parts itself, in order; roots on separate machines each run their own side and pass the files between them. A crashed run is retried by just re-running: completed roots skip, the rest write.

Step 5 is the second transfer: one `sed` marks `backup_suffix` with the same bare comment - the workflow's honest first act - and the same code move runs with `--transfer-target ../database`. Then step 4 again for its state.

## The window to respect

Between a code move landing and its state move completing, the source and that transfer's receiver plan dirty - `app` would destroy the moved resources, the receiver would duplicate them. In a real setup those roots' pipelines freeze the moment the code move merges, the state move runs immediately after, and `transfer migrate verify` reopens the world. Keep each window minutes long, not days. `cluster` never enters one, and each transfer's window only holds its own pair.

## The same story in CI

[`.github/workflows/transfer.yml`](.github/workflows/transfer.yml) runs the journey as the three lanes a real team would use; for illustration it targets the `pr-to-me` demo branch and nothing runs on `main`. The **slice-diff** lane is the standing gate on every PR: one matrix leg per touched root, each running a bare `transfer refactor diff` against that root and its own map copy - in a multi-repo landscape each leg is a different repo's whole gate. The **migrate-rehearse** lane builds the pre-transfer world from the PR's base commit, switches to the PR's code, and runs `migrate map` + `prove` - read-only, so a rejected PR leaves the world untouched. The **migrate** lane is `workflow_dispatch` only: a deliberate act taken once, after the merge, during the freeze; demonolith's own pins and receipts make re-running it safe and running it stale impossible. With two transfers, the lanes simply run twice - one PR and one dispatch per transfer.

## Handing the wiring to Snap CD

The first transfer left `roots/snapcd/main.tf` with the new `snapcd_module_input_from_output` and `snapcd_depends_on_module` blocks - the runtime form of the value the proofs threaded locally. To see it live, run a Snap CD server (for example [snapcd-deployment-docker](https://github.com/schrieksoft/snapcd/tree/main/serving/snapcd-deployment-docker), whose runner reaches this sample's store at `http://localhost:9000`), push this repo, and apply the root:

```
tofu -chdir=roots/snapcd init
tofu -chdir=roots/snapcd apply -var source_url=<your fork's git URL>
```

Snap CD then plans all four modules - producers before consumers, `networking`'s zone passed into `app`'s new input - and every one plans to zero changes: the same verdict `transfer migrate verify` reached, now delivered by the system that owns the ordering from here on.

## After

The moved resources have exactly one home: `networking`'s and `database`'s states gained them, `app`'s state lost them, and no resource was ever destroyed or recreated. `app`'s one new need - a value for its input - is met by Snap CD at runtime, which is precisely what the added wiring declares.

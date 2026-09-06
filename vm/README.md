---
title: iv-entire-agent-shelley
date: 2026-09-06
status: active qualification VM
---

# iv-entire-agent-shelley

This VM is a **test laboratory for the Shelley → Entire integration**.

Before IndustryVault changes the fleet-wide Entire CLI, Shelley, Python, base
image, or checkpoint backend, the combination is tested here. Successful test
evidence is committed to the
[`entire-agent-shelley`](https://github.com/kylelundstedt/entire-agent-shelley)
repository before provisioning pins change.

## What this VM does

- runs synthetic Shelley lifecycle and protocol tests;
- creates disposable real Entire checkpoints to test condensation and Git
  reconstruction;
- tests hook ordering, overlapping turns, failure isolation, repository
  registration, and checkpoint backends; and
- records which plugin and CLI versions have been qualified together.

## What this VM does not do

- It is **not** the central AgentsView collector; that is `iv-agentsview`.
- It is **not** a production transcript relay or shared capture service.
- Other VMs do not send their Shelley sessions here.
- It is not an ACR authority and does not approve repository changes.

Normal Shelley → Entire capture runs locally on each VM for each explicitly
enrolled repository. This VM exists only to prove that integration still works
before a new combination is rolled out.

## Current baseline

- Plugin: `entire-agent-shelley` `0.1.3`
- Entire CLI: `0.10.1`
- Entire external-agent protocol: `v1`
- Current evidence:
  [`QUALIFICATION-v0.1.3-cli0.10.1.md`](https://github.com/kylelundstedt/entire-agent-shelley/blob/main/QUALIFICATION-v0.1.3-cli0.10.1.md)

The VM itself is disposable. The repository and committed qualification reports
are the durable record.

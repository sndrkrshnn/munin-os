# MuninOS Agentic Architecture (Phase 1)

## Goal
Run a speech-first AI "brain" at OS level with tool-calling and agentic loops.

## Components

## 1) munin-audio (driver-coupled runtime)
Responsibilities:
- capture microphone frames and playback output frames
- keep low-latency ring-buffer streaming loop
- wake phrase path (`hey munin`) and locale boundary (`en-US` initially)
- forward transcript/stream events to `munin-brain`

## 2) munin-brain (adaptive decision engine)
Responsibilities:
- detect hardware profile (CPU/RAM/GPU hint)
- choose model tier automatically
- default optimized backend strategy: `llama.cpp`
- produce decisions and tool plans for file/system/network domains

## 3) munin-core (policy + execution runtime)
Responsibilities:
- enforce confirmation policy for risky actions
- execute tool calls and return structured results
- expose integration APIs for transcript ingestion + approvals

Implemented now:
- protocol event types (`Transcript`, `ToolCall`, `ToolResult`, `ResponseText`)
- policy engine (`file.write`, `shell.exec`, `network.post` require confirmation)
- tools:
  - `system.status`
  - `file.read`
  - `file.write`
  - `shell.exec`
  - `network.get`

## 3) munin-ui (visual shell)
Responsibilities:
- show listening/thinking/tool-call states
- display outputs and confirmations
- show confidence/errors

## Tool calling model
1. User speech -> transcript
2. Core chooses tool + arguments
3. Policy evaluates safety
4. Tool executes (or asks confirmation)
5. Result returned to speech + UI

## Phase 2+ foundation added
- `munin-core` API mode (`munin-core api --listen 0.0.0.0:8787`)
- transcript -> core handoff endpoint: `POST /v1/transcript`
- pending approval queue:
  - `GET /v1/pending`
  - `POST /v1/confirm` `{id, approve}`
- `munin-ui` polls pending approvals and provides approve/deny controls
- `munin-brain` API mode (`munin-brain serve --listen 0.0.0.0:8790`)
  - `POST /v1/decide`
  - `GET /health`
- `munin-audio` supports direct transcript injection into brain for pipeline testing

## Next steps
- replace rule-based planner with model-assisted planner
- persist pending actions/events to disk (SQLite)
- add scoped permissions per tool domain
- stream tool/event updates to UI via websocket

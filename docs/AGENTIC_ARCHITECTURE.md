# MuninOS Agentic Architecture (Phase 1)

## Goal
Run a speech-first AI "brain" at OS level with tool-calling and agentic loops.

## Components

## 1) munin-sts (speech runtime)
Responsibilities:
- capture mic input
- stream to S2S model endpoint (Qwen Omni / local SLM later)
- play spoken responses
- emit transcripts/events to core

## 2) munin-core (planner + tool router)
Responsibilities:
- parse transcript/intents
- decide tool calls
- apply policy checks (approval needed for risky actions)
- execute tools and synthesize final response

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

## Next steps
- replace rule-based planner with model-assisted planner
- add confirmation UX in UI (approve/deny)
- add persistent memory store for sessions
- add scoped permissions per tool domain

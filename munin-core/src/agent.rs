use crate::policy::PolicyEngine;
use crate::protocol::{CoreEvent, ToolCall, ToolResult};
use crate::tools::ToolRouter;
use anyhow::Result;
use serde_json::json;
use uuid::Uuid;

pub struct AgentRuntime {
    policy: PolicyEngine,
}

impl AgentRuntime {
    pub fn new() -> Self {
        Self { policy: PolicyEngine }
    }

    pub async fn handle_text(&self, input: &str, auto_approve: bool) -> Result<Vec<CoreEvent>> {
        let mut events = vec![CoreEvent::ResponseText(format!("Heard: {input}"))];

        let (tool, args) = decide_tool(input);
        let Some((tool, args)) = tool.zip(args) else {
            events.push(CoreEvent::ResponseText(
                "No tool selected. I can run: system status, read/write file, shell exec, network get.".into(),
            ));
            return Ok(events);
        };

        let decision = self.policy.evaluate(tool, &args);
        if !decision.allowed {
            events.push(CoreEvent::Error(decision.reason));
            return Ok(events);
        }

        let call = ToolCall {
            id: Uuid::new_v4().to_string(),
            tool: tool.to_string(),
            args: args.clone(),
            requires_confirmation: decision.requires_confirmation,
        };
        events.push(CoreEvent::ToolCall(call.clone()));

        if decision.requires_confirmation && !auto_approve {
            events.push(CoreEvent::ResponseText(format!(
                "Tool {} requires confirmation: {}",
                call.tool, decision.reason
            )));
            return Ok(events);
        }

        match ToolRouter::execute(&call.tool, &call.args).await {
            Ok(output) => events.push(CoreEvent::ToolResult(ToolResult {
                id: call.id,
                ok: true,
                output,
            })),
            Err(e) => events.push(CoreEvent::ToolResult(ToolResult {
                id: call.id,
                ok: false,
                output: json!({"error": e.to_string()}),
            })),
        }

        Ok(events)
    }
}

fn decide_tool(input: &str) -> (Option<&'static str>, Option<serde_json::Value>) {
    let low = input.to_lowercase();

    if low.contains("system status") || low == "status" {
        return (Some("system.status"), Some(json!({})));
    }
    if let Some(path) = low.strip_prefix("read ") {
        return (Some("file.read"), Some(json!({"path": path.trim()})));
    }
    if let Some(rest) = input.strip_prefix("write ") {
        if let Some((path, content)) = rest.split_once("::") {
            return (
                Some("file.write"),
                Some(json!({"path": path.trim(), "content": content.trim()})),
            );
        }
    }
    if let Some(cmd) = input.strip_prefix("exec ") {
        return (Some("shell.exec"), Some(json!({"command": cmd.trim()})));
    }
    if let Some(url) = input.strip_prefix("get ") {
        return (Some("network.get"), Some(json!({"url": url.trim()})));
    }

    (None, None)
}

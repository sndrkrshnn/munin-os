use serde_json::Value;

#[derive(Debug, Clone)]
pub struct PolicyDecision {
    pub allowed: bool,
    pub requires_confirmation: bool,
    pub reason: String,
}

#[derive(Default)]
pub struct PolicyEngine;

impl PolicyEngine {
    pub fn evaluate(&self, tool: &str, args: &Value) -> PolicyDecision {
        match tool {
            "shell.exec" => PolicyDecision {
                allowed: true,
                requires_confirmation: true,
                reason: "Shell execution can change system state".into(),
            },
            "file.write" => PolicyDecision {
                allowed: true,
                requires_confirmation: true,
                reason: "Writing files should be user-approved".into(),
            },
            "network.post" => PolicyDecision {
                allowed: true,
                requires_confirmation: true,
                reason: "Outbound data write requires approval".into(),
            },
            "file.read" | "network.get" | "system.status" => PolicyDecision {
                allowed: true,
                requires_confirmation: false,
                reason: "Read-only action".into(),
            },
            _ => PolicyDecision {
                allowed: false,
                requires_confirmation: false,
                reason: format!("Unknown or unsupported tool: {tool}; args={args}"),
            },
        }
    }
}

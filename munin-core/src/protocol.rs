use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpeechTurn {
    pub session_id: String,
    pub transcript: String,
    pub locale: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCall {
    pub id: String,
    pub tool: String,
    pub args: Value,
    pub requires_confirmation: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolResult {
    pub id: String,
    pub ok: bool,
    pub output: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "data")]
pub enum CoreEvent {
    Transcript(SpeechTurn),
    ToolCall(ToolCall),
    ToolResult(ToolResult),
    ResponseText(String),
    Error(String),
}

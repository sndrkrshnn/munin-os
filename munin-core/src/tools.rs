use anyhow::{anyhow, Context, Result};
use serde_json::{json, Value};
use tokio::process::Command;

pub struct ToolRouter;

impl ToolRouter {
    pub async fn execute(tool: &str, args: &Value) -> Result<Value> {
        match tool {
            "system.status" => Ok(system_status().await),
            "file.read" => file_read(args).await,
            "file.write" => file_write(args).await,
            "shell.exec" => shell_exec(args).await,
            "network.get" => network_get(args).await,
            _ => Err(anyhow!("unknown tool: {tool}")),
        }
    }
}

async fn system_status() -> Value {
    json!({
        "os": std::env::consts::OS,
        "arch": std::env::consts::ARCH,
        "uptime_hint": "Use shell.exec('uptime') for detailed uptime"
    })
}

async fn file_read(args: &Value) -> Result<Value> {
    let path = args.get("path").and_then(|v| v.as_str()).context("file.read requires args.path")?;
    let content = tokio::fs::read_to_string(path).await.with_context(|| format!("failed reading {path}"))?;
    Ok(json!({"path": path, "content": content}))
}

async fn file_write(args: &Value) -> Result<Value> {
    let path = args.get("path").and_then(|v| v.as_str()).context("file.write requires args.path")?;
    let content = args.get("content").and_then(|v| v.as_str()).context("file.write requires args.content")?;
    if let Some(parent) = std::path::Path::new(path).parent() {
        tokio::fs::create_dir_all(parent).await.ok();
    }
    tokio::fs::write(path, content).await.with_context(|| format!("failed writing {path}"))?;
    Ok(json!({"path": path, "written": content.len()}))
}

async fn shell_exec(args: &Value) -> Result<Value> {
    let command = args.get("command").and_then(|v| v.as_str()).context("shell.exec requires args.command")?;
    let output = Command::new("bash").arg("-lc").arg(command).output().await?;
    Ok(json!({
        "status": output.status.code().unwrap_or(-1),
        "stdout": String::from_utf8_lossy(&output.stdout),
        "stderr": String::from_utf8_lossy(&output.stderr)
    }))
}

async fn network_get(args: &Value) -> Result<Value> {
    let url = args.get("url").and_then(|v| v.as_str()).context("network.get requires args.url")?;
    let body = reqwest::get(url).await?.text().await?;
    let preview: String = body.chars().take(2000).collect();
    Ok(json!({"url": url, "preview": preview, "chars": body.len()}))
}

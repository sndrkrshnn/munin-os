use anyhow::Result;
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::collections::HashSet;
use std::io::Read;
use sysinfo::System;
use tiny_http::{Header, Method, Response, Server, StatusCode};

#[derive(Parser, Debug)]
#[command(name = "munin-brain")]
struct Args {
    #[command(subcommand)]
    command: Commands,

    #[arg(long, default_value = "en-US")]
    locale: String,

    #[arg(long, default_value = "hey munin")]
    wake_phrase: String,
}

#[derive(Subcommand, Debug)]
enum Commands {
    Profile,
    Decide { transcript: String },
    Serve {
        #[arg(long, default_value = "127.0.0.1:8790")]
        listen: String,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum ModelTier {
    Tier0Tiny,
    Tier1Mobile,
    Tier2Balanced,
    Tier3Performance,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct RuntimeProfile {
    arch: String,
    cpus: usize,
    ram_gb: u64,
    gpu_hint: bool,
    tier: ModelTier,
    backend: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Decision {
    intent: String,
    tool: Option<String>,
    args: serde_json::Value,
    requires_confirmation: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DecideIn {
    transcript: String,
    locale: Option<String>,
}

fn detect_profile() -> RuntimeProfile {
    let mut sys = System::new_all();
    sys.refresh_all();

    let ram_gb = (sys.total_memory() / 1024 / 1024) as u64;
    let cpus = num_cpus::get();
    let arch = std::env::consts::ARCH.to_string();

    // heuristic GPU hint: allow manual override
    let gpu_hint = std::env::var("MUNIN_GPU").ok().as_deref() == Some("1");

    let tier = if ram_gb <= 4 || cpus <= 2 {
        ModelTier::Tier0Tiny
    } else if ram_gb <= 8 || cpus <= 4 {
        ModelTier::Tier1Mobile
    } else if !gpu_hint {
        ModelTier::Tier2Balanced
    } else {
        ModelTier::Tier3Performance
    };

    // informed decision: prefer llama.cpp for optimized local inference path
    let backend = "llama.cpp".to_string();

    RuntimeProfile {
        arch,
        cpus,
        ram_gb,
        gpu_hint,
        tier,
        backend,
    }
}

fn decide(transcript: &str) -> Decision {
    let low = transcript.to_lowercase();

    if low.contains("status") {
        return Decision {
            intent: "system_status".into(),
            tool: Some("system.status".into()),
            args: json!({}),
            requires_confirmation: false,
        };
    }

    if let Some(path) = low.strip_prefix("read ") {
        return Decision {
            intent: "read_file".into(),
            tool: Some("file.read".into()),
            args: json!({"path": path.trim()}),
            requires_confirmation: false,
        };
    }

    if let Some(rest) = transcript.strip_prefix("write ") {
        if let Some((path, content)) = rest.split_once("::") {
            return Decision {
                intent: "write_file".into(),
                tool: Some("file.write".into()),
                args: json!({"path": path.trim(), "content": content.trim()}),
                requires_confirmation: true,
            };
        }
    }

    if let Some(cmd) = transcript.strip_prefix("exec ") {
        return Decision {
            intent: "system_exec".into(),
            tool: Some("system.exec".into()),
            args: json!({"command": cmd.trim()}),
            requires_confirmation: true,
        };
    }

    if let Some(url) = transcript.strip_prefix("get ") {
        return Decision {
            intent: "network_get".into(),
            tool: Some("network.get".into()),
            args: json!({"url": url.trim()}),
            requires_confirmation: false,
        };
    }

    Decision {
        intent: "chat".into(),
        tool: None,
        args: json!({"text": transcript}),
        requires_confirmation: false,
    }
}

fn serve_http(listen: &str) -> Result<()> {
    let server = Server::http(listen)?;
    tracing::info!("munin-brain api listening on http://{}", listen);
    for mut req in server.incoming_requests() {
        let path = req.url().to_string();
        let method = req.method().clone();

        let mut response = match (method, path.as_str()) {
            (Method::Get, "/health") => {
                Response::from_string(json!({"ok": true, "profile": detect_profile()}).to_string())
                    .with_status_code(StatusCode(200))
            }
            (Method::Post, "/v1/decide") => {
                let mut body = String::new();
                let _ = req.as_reader().read_to_string(&mut body);
                match serde_json::from_str::<DecideIn>(&body) {
                    Ok(input) => {
                        let decision = decide(&input.transcript);
                        Response::from_string(json!({"decision": decision}).to_string())
                            .with_status_code(StatusCode(200))
                    }
                    Err(e) => Response::from_string(json!({"error": e.to_string()}).to_string())
                        .with_status_code(StatusCode(400)),
                }
            }
            _ => Response::from_string(json!({"error": "not_found"}).to_string())
                .with_status_code(StatusCode(404)),
        };

        if let Ok(h) = Header::from_bytes("Content-Type", "application/json") {
            response = response.with_header(h);
        }
        let _ = req.respond(response);
    }

    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    let args = Args::parse();

    match args.command {
        Commands::Profile => {
            println!("{}", serde_json::to_string_pretty(&detect_profile())?);
        }
        Commands::Decide { transcript } => {
            println!("{}", serde_json::to_string_pretty(&decide(&transcript))?);
        }
        Commands::Serve { listen } => {
            tracing::info!("profile={:?}", detect_profile());
            serve_http(&listen)?;
        }
    }

    Ok(())
}

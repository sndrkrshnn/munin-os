use anyhow::Result;
use clap::{Parser, Subcommand};
use reqwest::Client;
use tokio::time::{sleep, Duration};
use tracing::info;
use uuid::Uuid;

#[derive(Parser, Debug)]
#[command(name = "munin-sts")]
#[command(author, version, about = "MuninOS local STS orchestration service")]
struct Args {
    #[command(subcommand)]
    command: Commands,

    #[arg(long, default_value_t = 16000)]
    sample_rate: u32,

    #[arg(long, default_value_t = 1)]
    channels: u16,

    #[arg(long, default_value_t = 100)]
    chunk_ms: u64,

    #[arg(long, default_value_t = true)]
    wake_word: bool,

    /// Munin core API endpoint (local)
    #[arg(long, default_value = "http://127.0.0.1:8787")]
    core_endpoint: String,

    /// Munin brain endpoint (local)
    #[arg(long, default_value = "http://127.0.0.1:8790")]
    brain_endpoint: String,
}

#[derive(Subcommand, Debug)]
enum Commands {
    Start,
    TestAudio,
    Interact { audio_file: String },
}

struct STSService {
    session_id: String,
    core_endpoint: String,
    brain_endpoint: String,
    client: Client,
}

impl STSService {
    fn new(args: &Args) -> Self {
        Self {
            session_id: Uuid::new_v4().to_string(),
            core_endpoint: args.core_endpoint.clone(),
            brain_endpoint: args.brain_endpoint.clone(),
            client: Client::new(),
        }
    }

    async fn run(&self) -> Result<()> {
        info!("Starting MuninOS STS session: {}", self.session_id);
        info!("Mode: local-only (no external API keys required)");

        let test_text = std::env::var("MUNIN_STS_TEST_TEXT").ok();

        loop {
            if let Some(text) = &test_text {
                let _ = self.route_transcript(text).await;
            }
            sleep(Duration::from_secs(3)).await;
            info!("STS service alive");
        }
    }

    async fn route_transcript(&self, transcript: &str) -> Result<()> {
        let decide_url = format!("{}/v1/decide", self.brain_endpoint.trim_end_matches('/'));
        let decide_payload = serde_json::json!({
            "transcript": transcript,
            "locale": "en-US"
        });

        let decide_resp = self.client.post(&decide_url).json(&decide_payload).send().await?;
        let decide_json: serde_json::Value = decide_resp.json().await.unwrap_or_default();
        info!("brain decision: {}", decide_json);

        let core_url = format!("{}/v1/transcript", self.core_endpoint.trim_end_matches('/'));
        let core_payload = serde_json::json!({
            "session_id": self.session_id,
            "locale": "en-US",
            "transcript": transcript
        });

        let core_resp = self.client.post(&core_url).json(&core_payload).send().await?;
        let core_text = core_resp.text().await.unwrap_or_default();
        info!("core transcript response: {}", core_text);

        Ok(())
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    let args = Args::parse();

    match args.command {
        Commands::Start => {
            let service = STSService::new(&args);
            service.run().await?;
        }
        Commands::TestAudio => {
            info!("Audio test stub (TODO): direct driver loop + VAD");
        }
        Commands::Interact { audio_file } => {
            info!("Interact stub (TODO): processing file {}", audio_file);
        }
    }

    Ok(())
}

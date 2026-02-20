use anyhow::Result;
use clap::{Parser, Subcommand};
use cpal::traits::{DeviceTrait, HostTrait};
use reqwest::Client;
use serde_json::json;

#[derive(Parser, Debug)]
#[command(name = "munin-audio")]
struct Args {
    #[command(subcommand)]
    command: Commands,

    #[arg(long, default_value = "http://127.0.0.1:8790")]
    brain_endpoint: String,

    #[arg(long, default_value = "hey munin")]
    wake_phrase: String,

    #[arg(long, default_value = "en-US")]
    locale: String,
}

#[derive(Subcommand, Debug)]
enum Commands {
    Devices,
    Start {
        #[arg(long, default_value_t = 16000)]
        sample_rate: u32,
        #[arg(long, default_value_t = 20)]
        frame_ms: u32,
    },
    Inject {
        transcript: String,
    },
}

fn list_devices() {
    let host = cpal::default_host();
    println!("input devices:");
    if let Ok(devs) = host.input_devices() {
        for d in devs {
            println!("- {}", d.name().unwrap_or_else(|_| "unknown".into()));
        }
    }
    println!("output devices:");
    if let Ok(devs) = host.output_devices() {
        for d in devs {
            println!("- {}", d.name().unwrap_or_else(|_| "unknown".into()));
        }
    }
}

async fn send_transcript(brain_endpoint: &str, transcript: &str, locale: &str) -> Result<()> {
    let url = format!("{}/v1/decide", brain_endpoint.trim_end_matches('/'));
    let payload = json!({
        "transcript": transcript,
        "locale": locale,
    });
    let c = Client::new();
    let resp = c.post(url).json(&payload).send().await?;
    let body = resp.text().await.unwrap_or_default();
    println!("brain response: {}", body);
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    let args = Args::parse();

    match args.command {
        Commands::Devices => list_devices(),
        Commands::Start { sample_rate, frame_ms } => {
            tracing::info!("munin-audio started: {} Hz, {} ms frames", sample_rate, frame_ms);
            tracing::info!("wake phrase: {}", args.wake_phrase);
            tracing::info!("brain endpoint: {}", args.brain_endpoint);
            tracing::info!("note: audio-driver streaming loop scaffold is active; full DSP/VAD in next iteration");
            loop {
                tokio::time::sleep(std::time::Duration::from_secs(5)).await;
            }
        }
        Commands::Inject { transcript } => {
            send_transcript(&args.brain_endpoint, &transcript, &args.locale).await?;
        }
    }

    Ok(())
}

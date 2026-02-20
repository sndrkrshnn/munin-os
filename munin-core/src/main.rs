use anyhow::Result;
use clap::{Parser, Subcommand};
use tracing_subscriber;

mod agent;
mod bus;
mod policy;
mod protocol;
mod tools;
mod server;

use agent::AgentRuntime;
use bus::MessageBus;

#[derive(Parser, Debug)]
#[command(name = "munin-core")]
#[command(author, version, about, long_about = None)]
struct Args {
    #[command(subcommand)]
    command: Commands,

    /// Enable speech mode (STS integration)
    #[arg(long, default_value_t = false)]
    sts: bool,

    /// Auto-approve risky tool calls (dev mode)
    #[arg(long, default_value_t = false)]
    auto_approve: bool,

    /// Local brain endpoint
    #[arg(long, default_value = "http://127.0.0.1:8790")]
    brain_endpoint: String,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// Start the MuninOS agent core event loop
    Start,
    /// Send a command to the bus
    Send { message: String },
    /// List registered agents
    ListAgents,
    /// Run interactive agent REPL
    Repl,
    /// One-shot agent command
    Agent { input: String },
    /// Start HTTP API for STS/UI integration
    Api {
        #[arg(long, default_value = "0.0.0.0:8787")]
        listen: String,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let args = Args::parse();
    let bus = MessageBus::new().await?;
    let agent = AgentRuntime::new();

    match args.command {
        Commands::Start => {
            tracing::info!("Starting MuninOS Core with sts={}", args.sts);
            if args.sts {
                bus.start_voice_mode(args.brain_endpoint).await?;
            } else {
                bus.run().await?;
            }
        }
        Commands::Send { message } => {
            bus.send(bus::Topic::System, message).await?;
        }
        Commands::ListAgents => {
            let agents = bus.list_agents().await?;
            tracing::info!("Registered agents: {:?}", agents);
        }
        Commands::Repl => run_repl(&agent, args.auto_approve).await?,
        Commands::Agent { input } => run_one_shot(&agent, &input, args.auto_approve).await?,
        Commands::Api { listen } => {
            let state = server::ApiState::new(agent);
            server::serve(&listen, state)?;
        }
    }

    Ok(())
}

async fn run_one_shot(agent: &AgentRuntime, input: &str, auto_approve: bool) -> Result<()> {
    let events = agent.handle_text(input, auto_approve).await?;
    for ev in events {
        println!("{:?}", ev);
    }
    Ok(())
}

async fn run_repl(agent: &AgentRuntime, auto_approve: bool) -> Result<()> {
    use std::io::{self, Write};
    println!("MuninOS Agentic REPL");
    println!("Examples:");
    println!("  status");
    println!("  read /etc/hostname");
    println!("  write /tmp/hello.txt::hello from munin");
    println!("  exec uptime");
    println!("  get https://example.com");
    println!("Type 'quit' to exit.");

    let stdin = io::stdin();
    loop {
        print!("> ");
        io::stdout().flush()?;

        let mut input = String::new();
        if stdin.read_line(&mut input)? == 0 {
            break;
        }
        let input = input.trim();
        if input.eq_ignore_ascii_case("quit") || input.is_empty() {
            break;
        }

        let events = agent.handle_text(input, auto_approve).await?;
        for ev in events {
            println!("{:?}", ev);
        }
    }

    Ok(())
}

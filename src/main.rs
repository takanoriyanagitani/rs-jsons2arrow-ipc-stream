use clap::Parser;
use rs_jsons2arrow_ipc_stream::jsons2ipc;
use std::io::{stdin, stdout};

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Number of lines to use for schema inference
    #[arg(short, long, default_value_t = 100)]
    num_lines: usize,
}

fn main() {
    let args = Args::parse();

    let stdin = stdin();
    let stdout = stdout();
    if let Err(e) = jsons2ipc(stdin.lock(), stdout.lock(), args.num_lines) {
        eprintln!("Error: {}", e);
        std::process::exit(1);
    }
}

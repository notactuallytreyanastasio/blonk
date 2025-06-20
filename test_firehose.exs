# Test script to verify firehose connection
# Run with: mix run test_firehose.exs

require Logger

# Start the application
{:ok, _} = Application.ensure_all_started(:elixir_blonk)

Logger.info("Starting firehose test...")
Logger.info("Listening for posts with #vibe-* hashtags...")
Logger.info("Press Ctrl+C to stop")

# Keep the script running
Process.sleep(:infinity)
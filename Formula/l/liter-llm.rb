class LiterLlm < Formula
  desc "OpenAI-compatible LLM proxy server and MCP tool server"
  homepage "https://github.com/xberg-io/liter-llm"
  url "https://github.com/xberg-io/liter-llm/archive/refs/tags/v2.7.0.tar.gz"
  sha256 "e0de10abc9bf9eb9a51c1e5111a84a2900970f87d3aa59363a73c63c4fe20be3"
  license "MIT"
  head "https://github.com/xberg-io/liter-llm.git", branch: "main"

  depends_on "rust" => :build

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/liter-llm-cli")
  end

  test do
    (testpath/"valid.toml").write <<~TOML
      [general]
      master_key = "sk-test"
    TOML
    assert_equal '{"valid":true}', shell_output("#{bin}/liter-llm config-check --config valid.toml").strip

    (testpath/"invalid.toml").write <<~TOML
      [security]
      outbound_policy = "allowlist"
    TOML
    output = shell_output("#{bin}/liter-llm config-check --config invalid.toml", 1)
    assert_match '"code":"invalid_config"', output

    assert_match version.to_s, shell_output("#{bin}/liter-llm --version")
  end
end

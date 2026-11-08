class H2m < Formula
  desc "High-performance HTML to Markdown converter"
  homepage "https://github.com/xberg-io/html-to-markdown"
  url "https://github.com/xberg-io/html-to-markdown/archive/refs/tags/v3.22.0.tar.gz"
  sha256 "7a71c6b20218dda00e9f578db1370b04e410aa0e2ce542af130f74950d931934"
  license "MIT"
  head "https://github.com/xberg-io/html-to-markdown.git", branch: "main"

  depends_on "rust" => :build

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/html-to-markdown-cli")
    generate_completions_from_executable(bin/"h2m", "--generate-completion")
    generate_completions_from_executable(bin/"html-to-markdown", "--generate-completion")
    (man1/"html-to-markdown.1").write Utils.safe_popen_read(bin/"html-to-markdown", "--generate-man")
  end

  test do
    assert_equal "# Title\n\nContent\n",
                 pipe_output(bin/"h2m", "<h1>Title</h1><p>Content</p>", 0)

    (testpath/"test.html").write <<~HTML
      <ul><li><a href="https://brew.sh">Homebrew</a></li></ul>
      <p>This is <strong>bold</strong> text.</p>
    HTML
    output = shell_output("#{bin}/h2m test.html")
    assert_match "[Homebrew](https://brew.sh)", output
    assert_match "**bold**", output
    assert_equal output, shell_output("#{bin}/html-to-markdown test.html")
  end
end

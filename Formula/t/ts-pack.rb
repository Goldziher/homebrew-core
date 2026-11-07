class TsPack < Formula
  desc "Parse and analyze code in 300+ languages with bundled tree-sitter grammars"
  homepage "https://github.com/xberg-io/tree-sitter-language-pack"
  url "https://github.com/xberg-io/tree-sitter-language-pack/archive/refs/tags/v1.25.0.tar.gz"
  sha256 "9eeedbfde0776e6daa549b40508c648a662b3867a55d1aa4b42b4273bd031be9"
  license any_of: ["MIT", "Apache-2.0"]

  # The grammar source bundle is a release asset, so only a published release is buildable.
  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "zstd"

  # Generated parser.c, scanners and queries for every grammar the pack ships.
  # Without it build.rs clones each grammar repository or downloads this bundle.
  resource "parser-sources" do
    url "https://github.com/xberg-io/tree-sitter-language-pack/releases/download/v1.25.0/parser-sources-1.25.0.tar.zst"
    sha256 "e4872183c3758f8955c623c6103bc07261bb51553e0cd13b04e3192beb8c71f6"

    livecheck do
      formula :parent
    end
  end

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    resource("parser-sources").stage do
      # Stray object files in the 1.25.0 bundle; never link them.
      rm Dir["parsers/*/src/*.o"]
      (buildpath/"parsers").install Dir["parsers/*"]
    end

    ENV["PROJECT_ROOT"] = buildpath
    ENV["TSLP_OFFLINE"] = "1"
    ENV["TSLP_LANGUAGES"] = "all"
    ENV["TSLP_LINK_MODE"] = "static"
    ENV["ZSTD_SYS_USE_PKG_CONFIG"] = "1"

    system "cargo", "install", *std_cargo_args(path: "crates/ts-pack-cli")
    generate_completions_from_executable(bin/"ts-pack", "completions")
  end

  test do
    (testpath/"hello.py").write <<~PYTHON
      def greet(name):
          return f"Hello, {name}"
    PYTHON
    sexp = shell_output("#{bin}/ts-pack parse hello.py")
    assert_match "(module (function_definition name: (identifier)", sexp

    (testpath/"main.rs").write <<~RUST
      fn main() {
          println!("hi");
      }
    RUST
    json = JSON.parse(shell_output("#{bin}/ts-pack parse main.rs --format json"))
    assert_equal "rust", json["language"]
    refute json["has_errors"]

    assert_match "python", shell_output("#{bin}/ts-pack list")
  end
end

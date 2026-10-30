class Agento11y < Formula
  desc "CLI for the Grafana Agent Observability plugins"
  homepage "https://github.com/grafana/agento11y/tree/main/plugins/agento11y"
  url "https://github.com/grafana/agento11y/archive/refs/tags/plugins/agento11y/v0.55.0.tar.gz"
  version "0.55.0"
  sha256 "b5a25222db98dca6bc11d6effa898827837522107171979916cbdd35f9743942"
  license "Apache-2.0"
  head "https://github.com/grafana/agento11y.git", branch: "main"

  depends_on "go" => :build

  def install
    version_string = if build.head?
      "dev-#{Utils.git_short_head}"
    else
      "v#{version}"
    end

    cd "plugins/agento11y" do
      ldflags = %W[
        -s -w
        -X main.version=#{version_string}
      ]

      system "go", "build",
        "-buildvcs=false",
        *std_go_args(ldflags: ldflags, output: bin/"agento11y"),
        "./cmd/agento11y"
    end

    bin.install_symlink "agento11y" => "sigil"
  end

  test do
    expected = build.head? ? "dev-" : "v#{version}"
    assert_match expected, shell_output("#{bin}/agento11y --version")
    assert_match expected, shell_output("#{bin}/sigil --version")
  end
end

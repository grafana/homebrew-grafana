class Agento11y < Formula
  desc "CLI for the Grafana AI Observability (Sigil) agent plugins"
  homepage "https://github.com/grafana/agento11y/tree/main/plugins/agento11y"
  url "https://github.com/grafana/agento11y/archive/refs/tags/plugins/agento11y/v0.20.0.tar.gz"
  version "0.20.0"
  sha256 "f2999a7b499e322e6b9e760b4d403baa4894678564d072faefcf3113e17e3bf3"
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

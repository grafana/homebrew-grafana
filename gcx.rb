class Gcx < Formula
  desc "Grafana Cloud CLI"
  homepage "https://github.com/grafana/gcx"
  url "https://github.com/grafana/gcx/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "ebdea26a970e6c7307472c886b3c4a2e74831ddf59726911aa01475f8f41a9ea"
  license "Apache-2.0"
  head "https://github.com/grafana/gcx.git", branch: "main"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=v#{version}
      -X main.commit=homebrew
      -X main.date=#{time.iso8601}
    ]

    system "go", "build",
      "-buildvcs=false",
      *std_go_args(ldflags: ldflags, output: bin/"gcx"),
      "./cmd/gcx"

    generate_completions_from_executable(bin/"gcx", "completion")
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/gcx --version")
  end
end

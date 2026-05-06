class Gcx < Formula
  desc "Grafana Cloud CLI"
  homepage "https://github.com/grafana/gcx"
  url "https://github.com/grafana/gcx/archive/refs/tags/v0.2.13.tar.gz"
  sha256 "595e4e2911ec05e663b16af87205b0f36ad39f53f308fdee516745af79e78d1c"
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

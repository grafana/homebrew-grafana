class Gcx < Formula
  desc "Grafana Cloud CLI"
  homepage "https://github.com/grafana/gcx"
  url "https://github.com/grafana/gcx/archive/refs/tags/v1.9.0.tar.gz"
  sha256 "038dc8ffbffd82560d252966cf62190fb01b86b06f071a1ee916ba73d2e7bb74"
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

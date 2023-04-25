class GrafanaAgentFlow < Formula
  desc "Vendor-neutral programmable observability pipelines."
  homepage "https://grafana.com/docs/agent/latest/flow"
  url "https://github.com/grafana/agent/archive/refs/tags/v0.33.0.tar.gz"
  sha256 "1db6d3f29d0b2bba94e219faa0caa65ef15e251cc694ec617d44c3af1fff5c03"
  license "Apache-2.0"

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "yarn" => :build

  on_linux do
    depends_on "systemd" => :build
  end

  def install
    ldflags = %W[
      -s -w
      -X github.com/grafana/agent/pkg/build.Branch=HEAD
      -X github.com/grafana/agent/pkg/build.Version=v#{version}
      -X github.com/grafana/agent/pkg/build.BuildUser=#{tap.user}
      -X github.com/grafana/agent/pkg/build.BuildDate=#{time.iso8601}
    ]
    args = std_go_args(ldflags: ldflags) + %w[-tags=builtinassets,noebpf]

    # Build the UI, which is baked into the final binary when the builtinassets
    # tag is set.
    cd "web/ui" do
      system "yarn"
      system "yarn", "run", "build"
    end

    system "go", "build", *args, "-o", bin/"grafana-agent-flow", "./cmd/grafana-agent"
  end

  def post_install
    (etc/"grafana-agent-flow").mkpath
  end

  def caveats
    <<~EOS
      The agent uses a configuration file that you must customize before running:
        #{etc}/grafana-agent-flow/config.river
    EOS
  end

  service do
    run [
      opt_bin/"grafana-agent-flow", "run", etc/"grafana-agent/config.river",
      "--server.http.listen-addr=127.0.0.1:12345",
      "--storage.path=#{etc}/grafana-agent/data",
    ]
    environment_variables AGENT_MODE: "flow"
    keep_alive true
    log_path var/"log/grafana-agent.log"
    error_log_path var/"log/grafana-agent.err.log"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/grafana-agent-flow --version")

    port = free_port

    (testpath/"grafana-agent.river").write <<~EOS
      logging {
        level = "info"
      }
    EOS

    fork do
      ENV["AGENT_MODE"] = "flow"
      exec bin/"grafana-agent-flow", "run", "#{testpath}/grafana-agent.river",
        "--server.http.listen-addr=127.0.0.1:#{port}",
        "--storage.path=#{testpath}/data"
    end
    sleep 10

    output = shell_output("curl -s 127.0.0.1:#{port}/metrics")
    assert_match "agent_build_info", output
  end
end

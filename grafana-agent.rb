# typed: false
# frozen_string_literal: true

class GrafanaAgent < Formula
  desc "Prometheus Metrics, Loki Logs, and Tempo Traces, optimized for Grafana Cloud."
  homepage "https://grafana.com/docs/agent/"
  url "https://github.com/grafana/agent/archive/v0.21.1.tar.gz"
  sha256 "2079234f66a2a9e40c90bdbcf4c2ad60c2d7cdfd2fe3fe0a21b5adf7083e545d"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args, "./cmd/agent"
  end

  def post_install
    (etc/"grafana-agent").mkpath
  end

  def caveats
    <<~EOS
      The agent uses a configuration file that you must customize before running:
        #{etc}/grafana-agent/config.yml
    EOS
  end

  plist_options manual: "grafana-agent -config.file=#{HOMEBREW_PREFIX}/etc/grafana-agent/config.yml"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_bin}/grafana-agent</string>
            <string>-config.file</string>
            <string>#{etc}/grafana-agent/config.yml</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <false/>
          <key>StandardErrorPath</key>
          <string>#{var}/log/grafana-agent.err.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/grafana-agent.log</string>
        </dict>
      </plist>
    EOS
  end

  test do
    port = free_port

    (testpath/"grafana-agent.yml").write <<~EOS
      server:
        log_level: info
        http_listen_port: #{port}
        grpc_listen_port: #{free_port}
    EOS

    fork do
      exec bin/"grafana-agent", "-config.file=#{testpath}/grafana-agent.yml"
    end
    sleep 3

    output = shell_output("curl -s -XGET 127.0.0.1:#{port}/metrics")
    assert_match "agent_build_info", output
  end
end

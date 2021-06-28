# typed: false
# frozen_string_literal: true

class GrafanaCloudAgent < Formula
  desc "Lightweight subset of Prometheus and more, optimized for Grafana Cloud"
  homepage "https://grafana.com/products/cloud/"
  url "https://github.com/grafana/agent/archive/v0.15.0.tar.gz"
  sha256 "6ffe4bbfa0efeecb7f352a965ff5d315915bd58a1800b7fb9d7e41fce50655d5"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args, "./cmd/agent"
  end

  def post_install
    (etc/"grafana-cloud-agent").mkpath
  end

  def caveats
    <<~EOS
      The agent uses a configuration file that you must customize before running:
        #{etc}/grafana-cloud-agent/config.yml
    EOS
  end

  plist_options manual: "grafana-cloud-agent -config.file=#{HOMEBREW_PREFIX}/etc/grafana-cloud-agent.yml"

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
            <string>#{opt_bin}/grafana-cloud-agent</string>
            <string>-config.file</string>
            <string>#{etc}/grafana-cloud-agent/config.yml</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <false/>
          <key>StandardErrorPath</key>
          <string>#{var}/log/grafana-cloud-agent.err.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/grafana-cloud-agent.log</string>
        </dict>
      </plist>
    EOS
  end

  test do
    port = free_port

    (testpath/"grafana-cloud-agent.yml").write <<~EOS
      server:
        log_level: info
        http_listen_port: #{port}
        grpc_listen_port: #{free_port}
    EOS

    fork do
      exec bin/"grafana-cloud-agent", "-config.file=#{testpath}/grafana-cloud-agent.yml"
    end
    sleep 3

    output = shell_output("curl -s -XGET 127.0.0.1:#{port}/metrics")
    assert_match "agent_build_info", output
  end
end

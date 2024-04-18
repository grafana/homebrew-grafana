class Alloy < Formula
    desc "Vendor-agnostic OpenTelemetry Collector distribution with programmable pipelines"
    homepage "https://grafana.com/docs/alloy/latest"
    url "https://github.com/grafana/alloy/archive/refs/tags/v1.0.0.tar.gz"
    sha256 "422aa6ab7b9e606ebec2edcde79d6f26b6e648da85955fd1d5d08d6e33e7c537"
    license "Apache-2.0"
  
    on_linux do
      depends_on "systemd" => :build
    end
  
    on_mac do
      depends_on "go" => :build
      depends_on "node" => :build
      depends_on "yarn" => :build
    end
  
    def install
      if OS.mac?
        ldflags = %W[
          -s -w
          -X github.com/grafana/alloy/internal/build.Branch=HEAD
          -X github.com/grafana/alloy/internal/build.Version=v#{version}
          -X github.com/grafana/alloy/internal/build.BuildUser=#{tap.user}
          -X github.com/grafana/alloy/internal/build.BuildDate=#{time.iso8601}
        ]
        args = std_go_args(ldflags: ldflags) + %w[-tags=builtinassets,noebpf]
    
        # Build the UI, which is baked into the final binary when the builtinassets
        # tag is set.
        cd "internal/web/ui" do
          system "yarn"
          system "yarn", "run", "build"
        end
        system "go", "build", *args, "-o", bin/"alloy", "."

      else
        # Reuse released binaries
        resource("released-binary") do
          url "https://github.com/grafana/alloy/releases/download/v#{version}/alloy-#{OS::NAME}-#{Hardware::CPU.arch}.zip"
        end
        resource("released-binary").stage do
          bin.install "alloy-#{OS::NAME}-#{Hardware::CPU.arch}" => "alloy"
        end
      end

      (buildpath/"config.alloy").write <<~EOS
        logging {
          level  = "info"
          format = "logfmt"
        }
      EOS
  
      (etc/"alloy").install "config.alloy"
      mkdir_p (var/"lib/alloy/data")
    end
  
    def caveats
      <<~EOS
        Alloy uses a configuration file that you can customize before running:
          #{etc}/alloy/config.alloy
      EOS
    end
  
    service do
      run [
        opt_bin/"alloy", "run", etc/"alloy/config.alloy",
        "--server.http.listen-addr=127.0.0.1:12345",
        "--storage.path=#{var}/lib/alloy/data",
      ]
      keep_alive true
      log_path var/"log/alloy.log"
      error_log_path var/"log/alloy.err.log"
    end
  
    test do
      assert_match version.to_s, shell_output("#{bin}/alloy --version")
  
      port = free_port
  
      (testpath/"config.alloy").write <<~EOS
        logging {
          level = "info"
        }
      EOS
  
      fork do
        exec bin/"alloy", "run", "#{testpath}/config.alloy",
          "--server.http.listen-addr=127.0.0.1:#{port}",
          "--storage.path=#{testpath}/data"
      end
      sleep 10
  
      output = shell_output("curl -s 127.0.0.1:#{port}/metrics")
      assert_match "alloy_build_info", output
    end
  end
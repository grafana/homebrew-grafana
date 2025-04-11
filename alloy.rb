class Alloy < Formula
    desc "Vendor-agnostic OpenTelemetry Collector distribution with programmable pipelines"
    homepage "https://grafana.com/docs/alloy/latest"
    url "https://github.com/grafana/alloy/archive/refs/tags/v1.8.1.tar.gz"
    # To get the sha256sum, run the following command, replacing the version number with the version you want to check:
    # wget https://github.com/grafana/alloy/archive/refs/tags/v1.8.1.tar.gz && sha256sum v1.8.1.tar.gz && rm v1.8.1.tar.gz
    sha256 "f6a4cb6c74a798e2f3337030d4c7824e8195c8cb54df5d9620f5345f018fc2b6"
    license "Apache-2.0"
  
    depends_on "go@1.24" => :build
    depends_on "node@20" => :build
    depends_on "yarn" => :build

    on_linux do
      depends_on "systemd" => :build
    end

    def install
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

      # Create a config.alloy file with default Alloy configuration
      (buildpath/"config.alloy").write <<~EOS
        logging {
          level  = "info"
          format = "logfmt"
        }
      EOS

      (etc/"alloy").install "config.alloy"

      # Create an empty config.env file for environment variables
      (buildpath/"config.env").write ""
      (etc/"alloy").install "config.env"

      # Create an empty extra-args.txt file for extra command line arguments
      (buildpath/"extra-args.txt").write ""
      (etc/"alloy").install "extra-args.txt"

      # Create a wrapper script to run Alloy using the config in config.alloy,
      # env vars in config.env, and extra args in extra-args.txt
      (buildpath/"alloy-wrapper").write <<~SH
      #!/usr/bin/env sh
      source "#{etc}/alloy/config.env"

      COMMAND="#{opt_bin}/alloy run #{etc}/alloy/config.alloy \
      --server.http.listen-addr=0.0.0.0:12345 \
      --storage.path=#{var}/lib/alloy/data"

      EXTRA_ARGS=$(cat "#{etc}/alloy/extra-args.txt")

      if [ -z "$EXTRA_ARGS" ]; then
        exec $COMMAND
      else
        exec $COMMAND $EXTRA_ARGS
      fi
      SH

      bin.install "alloy-wrapper"
      (bin/"alloy-wrapper").chmod 0755

      mkdir_p (var/"lib/alloy/data")
    end

    def caveats
      <<~EOS
        Alloy uses a set of files that you can customize before running:
          Configuration:
            #{etc}/alloy/config.alloy
          Environment variables:
            #{etc}/alloy/config.env
          Extra command line arguments:
            #{etc}/alloy/extra-args.txt
      EOS
    end

    service do
      run ["#{opt_bin}/alloy-wrapper"]
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

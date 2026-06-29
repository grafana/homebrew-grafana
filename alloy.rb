class Alloy < Formula
    desc "Vendor-agnostic OpenTelemetry Collector distribution with programmable pipelines"
    homepage "https://grafana.com/docs/alloy/latest"
    url "https://github.com/grafana/alloy/archive/refs/tags/v1.17.1.tar.gz"
    # To get the sha256sum, run the following command, replacing the version number with the version you want to check:
    # wget https://github.com/grafana/alloy/archive/refs/tags/v1.17.1.tar.gz && sha256sum v1.17.1.tar.gz && rm v1.17.0.tar.gz
    sha256 "a3072c30a70901764bb31f26c7fa126cf1f625ac5c34e7cd407fcefad8c8f461"
    license "Apache-2.0"
  
    depends_on "go@1.26" => :build
    depends_on "node@24" => :build

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
      # https://github.com/grafana/alloy/blob/main/tools/make/packaging.mk
      tags = %w[netgo embedalloyui gore2regex]
      tags << "promtail_journal_enabled" if OS.linux?

      # Build the UI, which is baked into the final binary when the embedalloyui
      # tag is set.
      cd "internal/web/ui" do
        system "npm", "install", *std_npm_args(prefix: false)
        system "npm", "run", "build"
      end

      system "go", "build", "-C", "collector", *std_go_args(ldflags:, tags:, output: bin/"alloy")

      generate_completions_from_executable(bin/"alloy", shell_parameter_format: :cobra)

      # Create a config.alloy file with default Alloy configuration
      (buildpath/"config.alloy").write <<~EOS
        logging {
          level  = "info"
          format = "logfmt"
        }
      EOS

      pkgetc.install "config.alloy"

      # Create an empty config.env file for environment variables
      (buildpath/"config.env").write ""
      pkgetc.install "config.env"

      # Create an empty extra-args.txt file for extra command line arguments
      (buildpath/"extra-args.txt").write ""
      pkgetc.install "extra-args.txt"

      # Create a wrapper script to run Alloy using the config in config.alloy,
      # env vars in config.env, and extra args in extra-args.txt
      system "go", "run",
        "-C", "packaging/homebrew/service-wrapper-gen", ".",
        "-alloy-bin", "#{opt_bin}/alloy",
        "-config-path", "#{pkgetc}",
        "-env-file", "#{pkgetc}/config.env",
        "-extra-args-file", "#{pkgetc}/extra-args.txt",
        "-otel-extra-args-file", "#{pkgetc}/otel-extra-args.txt",
        "-storage-path", "#{var}/lib/alloy/data",
        "-out", "#{buildpath}/alloy-wrapper"

      bin.install "alloy-wrapper"
      mkdir_p (var/"lib/alloy/data")
    end

    def caveats
      <<~EOS
        Alloy uses a set of files that you can customize before running:
          Configuration:
            #{pkgetc}/config.alloy
          Environment variables:
            #{pkgetc}/config.env
          Extra command line arguments:
            #{pkgetc}/extra-args.txt

        To enable the OTel Engine:
          - Set "ALLOY_OTEL_MODE=1" in #{pkgetc}/config.env
          - Create collector config in #{pkgetc}/config.yaml
          - If necessary, create #{pkgetc}/otel-extra-args.txt to add command line arguments.
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

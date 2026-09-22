class Tempo < Formula
    desc "Grafana Tempo is a high volume, minimal dependency distributed tracing backend"
    homepage "https://grafana.com/docs/tempo/latest"
    url "https://github.com/grafana/tempo/archive/refs/tags/v2.4.2.tar.gz"
    sha256 "f31403772040c219b80893e6951c4613c94945937ab2b07f610dce44820d34e5"
    license "Apache-2.0"

    depends_on "go" => :build
    #depends_on "node" => :build
    #depends_on "yarn" => :build

    on_linux do
      depends_on "systemd" => :build
    end

    def install
      # ldflags = %W[
      #   -s -w
      #   -X github.com/grafana/tempo/internal/build.Branch=HEAD
      #   -X github.com/grafana/tempo/internal/build.Version=v#{version}
      #   -X github.com/grafana/tempo/internal/build.BuildUser=#{tap.user}
      #   -X github.com/grafana/tempo/internal/build.BuildDate=#{time.iso8601}
      # ]
      # args = std_go_args(ldflags: ldflags) + %w[-tags=builtinassets,noebpf]

      #GO111MODULE=on CGO_ENABLED=0 go build $(GO_OPT) -o ./bin/$(GOOS)/tempo-$(GOARCH) $(BUILD_INFO) ./cmd/tempo
      #system "GO111MODULE=on", "go", "build", *args, "-o", bin/"tempo", "./cmd/tempo"
      system "go", "build","-o", bin/"tempo", "./cmd/tempo"
    	# GO111MODULE=on CGO_ENABLED=0 go build $(GO_OPT) -o ./bin/$(GOOS)/tempo-query-$(GOARCH) $(BUILD_INFO) ./cmd/tempo-query
      #system "go", "build", "-o", bin/"tempo-query", "./cmd/tempo-query"
  	  # GO111MODULE=on CGO_ENABLED=0 go build $(GO_OPT) -o ./bin/$(GOOS)/tempo-cli-$(GOARCH) $(BUILD_INFO) ./cmd/tempo-cli
      system "go", "build", "-o", bin/"tempo-cli", "./cmd/tempo-cli"
	    # GO111MODULE=on CGO_ENABLED=0 go build $(GO_OPT) -o ./bin/$(GOOS)/tempo-vulture-$(GOARCH) $(BUILD_INFO) ./cmd/tempo-vulture
      #system "go", "build", "-o", bin/"tempo-vulture", "./cmd/tempo-vulture"

      (buildpath/"config.tempo").write <<~EOS
      stream_over_http_enabled: true
      server:
        http_listen_port: 3200
        log_level: info
      
      query_frontend:
        search:
          duration_slo: 5s
          throughput_bytes_slo: 1.073741824e+09
        trace_by_id:
          duration_slo: 5s
      
      distributor:
        receivers:                           # this configuration will listen on all ports and protocols that tempo is capable of.
          jaeger:                            # the receives all come from the OpenTelemetry collector.  more configuration information can
            protocols:                       # be found there: https://github.com/open-telemetry/opentelemetry-collector/tree/main/receiver
              thrift_http:                   #
              grpc:                          # for a production deployment you should only enable the receivers you need!
              thrift_binary:
              thrift_compact:
          zipkin:
          otlp:
            protocols:
              http:
              grpc:
          opencensus:
      
      ingester:
        max_block_duration: 5m               # cut the headblock when this much time passes. this is being set for demo purposes and should probably be left alone normally
      
      compactor:
        compaction:
          block_retention: 1h                # overall Tempo trace retention. set for demo purposes
      
      metrics_generator:
        registry:
          external_labels:
            source: tempo
            cluster: docker-compose
        storage:
          path: /opt/homebrew/var/tempo/generator/wal
          remote_write:
            - url: http://prometheus:9090/api/v1/write
              send_exemplars: true
        traces_storage:
          path: /opt/homebrew/var/tempo/generator/traces
      
      storage:
        trace:
          backend: local                     # backend configuration to use
          wal:
            path: /opt/homebrew/var/tempo/wal             # where to store the wal locally
          local:
            path: /opt/homebrew/var/tempo/blocks
      
      overrides:
        defaults:
          metrics_generator:
            processors: [service-graphs, span-metrics, local-blocks] # enables metrics generator
      EOS

      (etc/"tempo").install "config.tempo"
      mkdir_p (var/"tempo")
    end

    def caveats
      <<~EOS
        Tempo uses a configuration file that you can customize before running:
          #{etc}/tempo/config.tempo
      EOS
    end

    service do
      run [
        opt_bin/"tempo", "-config.file", etc/"tempo/config.tempo",
      ]
      keep_alive true
      log_path var/"log/tempo.log"
      error_log_path var/"log/tempo.err.log"
    end

    test do
      assert_match version.to_s, shell_output("#{bin}/tempo --version")
    end
  end

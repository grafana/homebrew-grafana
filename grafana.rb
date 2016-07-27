require "language/node"

class Grafana < Formula
  desc "Gorgeous metric visualizations and dashboards for timeseries databases."
  homepage "http://grafana.org"
  url "https://github.com/grafana/grafana/archive/v3.1.0.tar.gz"
  sha256 "658c858e905ecb05e03aabf57ce02184b484f98e1fb979b67d26e16dfd93196a"

  head "https://github.com/grafana/grafana.git"

  depends_on "go" => :build
  depends_on "node" => :build

  def install
    ENV["GOPATH"] = buildpath
    grafana_path = buildpath/"src/github.com/grafana/grafana"
    grafana_path.install Dir["*"]
    grafana_path.install ".jscs.json", ".jsfmtrc", ".jshintrc", ".bowerrc"

    cd grafana_path do
      system "go", "run", "build.go", "setup"
      system "go", "run", "build.go", "build"
      system "npm", "install", *Language::Node.local_npm_install_args
      system "npm", "install", "grunt-cli", *Language::Node.local_npm_install_args
      system "node_modules/grunt-cli/bin/grunt", "build"

      bin.install "bin/grafana-cli"
      bin.install "bin/grafana-server"
      (bin/"grafana").write(env_script)
      chmod 0755, bin/"grafana"
      (etc/"grafana").mkpath
      cp("conf/sample.ini", "conf/grafana.ini.example")
      etc.install "conf/sample.ini" => "grafana/grafana.ini"
      etc.install "conf/grafana.ini.example" => "grafana/grafana.ini.example"
      pkgshare.install "conf", "vendor"
      pkgshare.install "public_gen" => "public"
    end
  end

  def post_install
    (var/"log/grafana").mkpath
    (var/"lib/grafana/plugins").mkpath
  end

  def env_script
    <<-EOS.undent
      #!/usr/bin/env bash
      DAEMON=grafana-server
      EXECUTABLE=#{bin/"grafana-server"}
      CONFIG=#{etc}/grafana/grafana.ini
      HOMEPATH=#{pkgshare}
      LOGPATH=#{var}/log/grafana
      DATAPATH=#{var}/lib/grafana
      PLUGINPATH=#{var}/lib/grafana/plugins

      case "$1" in
      start)
        $EXECUTABLE --config=$CONFIG --homepath=$HOMEPATH cfg:default.paths.logs=$LOGPATH cfg:default.paths.data=$DATAPATH cfg:default.paths.plugins=$PLUGINPATH 2> /dev/null &
        [ $? -eq 0 ] && echo "$DAEMON started"
      ;;
      stop)
        killall $DAEMON
        [ $? -eq 0 ] && echo "$DAEMON stopped"
      ;;
      restart)
        $0 stop
        $0 start
      ;;
      *)
        echo "Usage: $0 (start|stop|restart)"
      ;;
      esac
    EOS
  end

  plist_options :manual => "grafana start"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>KeepAlive</key>
        <dict>
          <key>SuccessfulExit</key>
          <false/>
        </dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/grafana-server</string>
          <string>--config</string>
          <string>#{etc}/grafana/grafana.ini</string>
          <string>--homepath</string>
          <string>#{opt_pkgshare}</string>
          <string>cfg:default.paths.logs=#{var}/log/grafana</string>
          <string>cfg:default.paths.data=#{var}/lib/grafana</string>
          <string>cfg:default.paths.plugins=#{var}/lib/grafana/plugins</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{var}/share/grafana</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/grafana/grafana-stderr.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/grafana/grafana-stdout.log</string>
        <key>SoftResourceLimits</key>
        <dict>
          <key>NumberOfFiles</key>
          <integer>10240</integer>
        </dict>
      </dict>
    </plist>
   EOS
  end

  test do
    require "pty"
    require "timeout"

    # first test
    system bin/"grafana-server", "-v"

    # avoid stepping on anything that may be present in this directory
    tdir = File.join(Dir.pwd, "grafana-test")
    Dir.mkdir(tdir)
    logdir = File.join(tdir, "log")
    datadir = File.join(tdir, "data")
    plugdir = File.join(tdir, "plugins")
    [logdir, datadir, plugdir].each do |d|
      Dir.mkdir(d)
    end
    Dir.chdir(pkgshare)

    res = PTY.spawn(bin/"grafana-server", "cfg:default.paths.logs=#{logdir}", "cfg:default.paths.data=#{datadir}", "cfg:default.paths.plugins=#{plugdir}", "cfg:default.server.http_port=50100")
    r = res[0]
    w = res[1]
    pid = res[2]

    listening = Timeout.timeout(5) do
      li = false
      r.each do |l|
        if l =~ /Listen/
          li = true
          break
        end
      end
      li
    end

    Process.kill("TERM", pid)
    w.close
    r.close
    listening
  end
end

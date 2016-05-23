require "language/go"

class Grafana < Formula
  desc "Gorgeous metric viz, dashboards & editors for Graphite, InfluxDB & OpenTSDB."
  homepage "https://grafana.org"
  url "https://github.com/grafana/grafana/archive/v3.0.3.tar.gz"
  version "3.0.3"
  sha256 "4ff16ea6282439d09f8dc2b501de66108cfdfbbe0c0af04cfbf4444191111297"

  head "https://github.com/grafana/grafana.git"

  depends_on "go" => :build
  depends_on "nodejs" => :build

  def install
    ENV.prepend_path "PATH", "#{Formula["node"].opt_libexec}/npm/bin"
    ENV["GOPATH"] = buildpath
    grafana_path = buildpath/"src/github.com/grafana/grafana"
    grafana_path.install Dir["*"]
    grafana_path.install ".jscs.json", ".jsfmtrc", ".jshintrc", ".bowerrc"

    Language::Go.stage_deps resources, buildpath/"src"
    
    cd grafana_path do
      # Might do it differently for head vs. release
      system "go", "run", "build.go", "setup"
      system "go", "run", "build.go", "build"
      system "npm", "install"
      system "npm", "install", "grunt-cli"
      system "node_modules/grunt-cli/bin/grunt", "build"
    end

    FileUtils.cp(grafana_path/"conf/sample.ini", grafana_path/"conf/grafana.ini")

    bin.install grafana_path/"bin/grafana-cli"
    bin.install grafana_path/"bin/grafana-server"
    (etc/"grafana").mkpath
    (var/"log/grafana").mkpath
    (var/"lib/grafana").mkpath
    (var/"lib/grafana/plugins").mkpath
    etc.install grafana_path/"conf/grafana.ini" => "grafana/grafana.ini"
    pkgshare.install Dir[grafana_path/"conf", grafana_path/"public_gen", grafana_path/"vendor"]
    mv pkgshare/"public_gen", pkgshare/"public"
  end

  plist_options :manual => "grafana-server --config=#{HOMEBREW_PREFIX}/etc/grafana/grafana.ini --homepath #{HOMEBREW_PREFIX}/share/grafana cfg:default.paths.logs=#{HOMEBREW_PREFIX}/var/log/grafana cfg:default.paths.data=#{HOMEBREW_PREFIX}/var/lib/grafana cfg:default.paths.plugins=#{HOMEBREW_PREFIX}/var/lib/grafana/plugins"

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
          <string>#{HOMEBREW_PREFIX}/etc/grafana/grafana.ini</string>
	  <string>--homepath</string>
	  <string>#{HOMEBREW_PREFIX}/share/grafana</string>
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
    system bin/"grafana-server", "-v"
  end
end

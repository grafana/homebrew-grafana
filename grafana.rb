# typed: false
# frozen_string_literal: true

require "language/node"

class Grafana < Formula
  desc "Gorgeous metric visualizations and dashboards for timeseries databases"
  homepage "https://grafana.com"
  url "https://github.com/grafana/grafana/archive/v4.3.0.tar.gz"
  sha256 "d81e5fdb7ac702646a4b17343796970c91000ea5ea2036880e0e3e36c7a0a8a5"

  head "https://github.com/grafana/grafana.git"

  bottle do
    sha256 cellar: :any_skip_relocation, sierra:     "7c7bcf3fa6db1c54dc94ab030ac0c8adc3d20761e695446ba13c1db98c6568d4"
    sha256 cellar: :any_skip_relocation, el_capitan: "96f30bf66355d985b23b39d2466f23e6a83455a4c9a1b9479eefaacc6415ef64"
    sha256 cellar: :any_skip_relocation, yosemite:   "41b6bca25925ab369383de74667e0b2ed5a79db8003ff3f3b82c73eeab5d047e"
  end

  deprecate! date: "2021-06-28", because: "is not maintained; use grafana formula from homebrew-core instead (brew uninstall grafana/grafana/grafana && brew install grafana)"

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "yarn" => :build

  def install
    ENV["GOPATH"] = buildpath
    grafana_path = buildpath/"src/github.com/grafana/grafana"
    grafana_path.install buildpath.children

    cd grafana_path do
      system "go", "run", "build.go", "build"
      system "yarn", "install"
      system "npm", "install", "grunt-cli", *Language::Node.local_npm_install_args

      args = ["build"]
      # Avoid PhantomJS error "unrecognized selector sent to instance"
      args << "--force" unless build.bottle?
      system "node_modules/grunt-cli/bin/grunt", *args

      bin.install "bin/grafana-cli"
      bin.install "bin/grafana-server"
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

  service do
    run [
      opt_bin/"grafana-server",
      "--config",
      etc/"grafana/grafana.ini",
      "--homepath",
      opt_pkgshare,
      "cfg:default.paths.logs=#{var}/log/grafana",
      "cfg:default.paths.data=#{var}/lib/grafana",
      "cfg:default.paths.plugins=#{var}/lib/grafana/plugins",
    ]
    keep_alive successful_exit: false
    working_dir var/"lib/grafana"
    log_path var/"log/grafana/grafana-stdout.log"
    error_log_path var/"log/grafana/grafana-stderr.log"
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

    res = PTY.spawn(bin/"grafana-server", "cfg:default.paths.logs=#{logdir}", "cfg:default.paths.data=#{datadir}",
                    "cfg:default.paths.plugins=#{plugdir}", "cfg:default.server.http_port=50100")
    r = res[0]
    w = res[1]
    pid = res[2]

    listening = Timeout.timeout(5) do
      li = false
      r.each do |l|
        if /Initializing HTTP Server/.match?(l)
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

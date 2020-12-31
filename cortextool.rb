# This file was generated by GoReleaser. DO NOT EDIT.
class Cortextool < Formula
  desc "Tools for interacting with Cortex"
  homepage "https://grafana.com"
  version "0.7.0"
  bottle :unneeded

  if OS.mac?
    url "https://github.com/grafana/cortex-tools/releases/download/v0.7.0/cortextool_0.7.0_darwin_amd64.tar.gz"
    sha256 "9486a568aa5733b1cd26b73136c9f0904327929bd2254692d8225b0b0b7040cb"
  elsif OS.linux?
    if Hardware::CPU.intel?
      url "https://github.com/grafana/cortex-tools/releases/download/v0.7.0/cortextool_0.7.0_linux_amd64.tar.gz"
      sha256 "099f6be8117a9c20f9aff443c05a30c4a0ac9b9ad2f68e8e57bde4b6d3a01039"
    end
  end

  def install
    bin.install "cortextool"
  end
end

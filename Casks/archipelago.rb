cask "archipelago" do
  version "0.2.0,230"
  sha256 "e9cbc58dfa7e3e37c89b185f95437eb30d9d5af767e8c507bd7884e07ebea3f1"

  url "https://github.com/anuragdeshpande/homebrew-tap/releases/download/v#{version.csv.first}-build.#{version.csv.second}/Archipelago.dmg"
  name "Archipelago"
  desc "Universal macOS Notch, Dynamic Island, and Pill surface engine"
  homepage "https://github.com/anuragdeshpande/homebrew-tap"

  livecheck do
    url "https://github.com/anuragdeshpande/homebrew-tap/releases/latest/download/appcast.xml"
    strategy :sparkle
  end

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "Archipelago.app"
  binary "#{appdir}/Archipelago.app/Contents/MacOS/tools/archipelago"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Archipelago.app"],
                   sudo: false
  end

  uninstall quit: "com.archipelago.app"

  zap trash: [
    "~/Library/Application Support/Archipelago",
    "~/Library/Caches/com.archipelago.app",
    "~/Library/HTTPStorages/com.archipelago.app",
    "~/Library/Preferences/com.archipelago.app.plist",
  ]
end

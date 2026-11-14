cask "archipelago" do
  version "0.2.0,229"
  sha256 "31018186b1e4278b43abf4b7c1f4ef87b2fe37c875ed140a9d6619556f522485"

  url "https://github.com/anuragdeshpande/archipelago-universal/releases/download/v#{version.csv.first}-build.#{version.csv.second}/Archipelago.dmg"
  name "Archipelago"
  desc "Universal macOS Notch, Dynamic Island, and Pill surface engine"
  homepage "https://github.com/anuragdeshpande/archipelago-universal"

  livecheck do
    url "https://github.com/anuragdeshpande/archipelago-universal/releases/latest/download/appcast.xml"
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

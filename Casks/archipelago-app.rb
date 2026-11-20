cask "archipelago-app" do
  version "0.12.3,356"
  sha256 "8b6ecf3cb964d5bfa4227c2b034f185f3e7b634925d8f6adcd3b5bc563b443cc"

  url "https://github.com/anuragdeshpande/homebrew-tap/releases/download/v#{version.csv.first}-build.#{version.csv.second}/Archipelago.dmg"
  name "Archipelago"
  desc "Universal macOS Notch, Dynamic Island, and Pill surface engine"
  homepage "https://github.com/anuragdeshpande/homebrew-tap"

  livecheck do
    url "https://github.com/anuragdeshpande/homebrew-tap/releases/latest/download/appcast.xml"
    strategy :sparkle
  end

  auto_updates true
  depends_on macos: :sonoma

  app "Archipelago.app"
  binary "#{appdir}/Archipelago.app/Contents/MacOS/tools/archipelago"

  postflight_steps do
    run "/usr/bin/xattr", args: ["-cr", "{{appdir}}/Archipelago.app"]
  end

  uninstall quit: "com.archipelago.app"

  zap trash: [
    "~/Library/Application Support/Archipelago",
    "~/Library/Caches/com.archipelago.app",
    "~/Library/HTTPStorages/com.archipelago.app",
    "~/Library/Preferences/com.archipelago.app.plist",
  ]
end

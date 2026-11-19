cask "archipelago-app" do
  version "0.10.2,339"
  sha256 "b9b94b15682deaa3207700cec2dfb9db0aa898a28e9e8773aef71fe2d62a5827"

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

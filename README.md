# Pacer for vívoactive 5

Pacer emits two vibration cues per breathing cycle: one at each inhale/exhale boundary. The upper physical Action button opens the on-watch settings menu. Screen taps do nothing on the main screen.

The selected values are stored on the watch and survive app restarts:

| Setting | Default | Range |
| --- | ---: | ---: |
| Breathing pace | 5.71 breaths/min | 4.50–6.50 in 0.01 steps |
| Vibration strength | 15% | 0–100% in 5% steps |
| Vibration length | 170 ms | 50–1000 ms in 10 ms steps |

The pace range covers the adult resonance frequency band. The default of 5.71
breaths/min is a personally measured resonance frequency, not a generic value;
re-measure and adjust it in the on-watch settings rather than in code.

The main screen shows the app version. That is the way to confirm which build
is actually running on the watch after a side-load — see `publish.sh` below.

Setting vibration strength to 0% mutes the cues without changing the saved pace.

A right swipe on the main screen is consumed so it does not close the app. Garmin exposes both that swipe and the lower physical Back button as the same Back behavior, so the lower button is also locked on the main screen. Use `Pacer settings > Exit Pacer` to exit deliberately. Swiping back from a picker or the settings menu only returns to the previous Pacer screen.

## Build on a clean computer

### 1. Install the prerequisites

1. Install a 64-bit Java runtime or JDK, version 11 or newer. Java 17 LTS is a conservative choice.
2. Download and install Garmin Connect IQ SDK Manager from <https://developer.garmin.com/connect-iq/sdk/>.
3. In SDK Manager, install the current Connect IQ SDK and the **vívoactive 5** device package, then make that SDK active.
4. In Visual Studio Code, install the **Monkey C** extension published by Garmin.
5. Run `Monkey C: Verify Installation` from the VS Code command palette.

Garmin's current setup instructions are at:

- <https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/>
- <https://developer.garmin.com/connect-iq/reference-guides/visual-studio-code-extension/>
- <https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/>

### macOS command-line setup

Garmin stores the selected SDK path in `~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`. Add that SDK's tools to the current Terminal session and verify them with:

```bash
export PATH="$PATH:$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")/bin"
command -v java monkeyc monkeydo connectiq
```

To make the SDK tools available in future zsh sessions, add that `export` line to `~/.zshrc`.

Clone the project and enter its directory:

```bash
git clone https://github.com/BogdanYarotsky/pacer.git
cd pacer
```

### Windows command-line setup

The included `build.ps1` finds the active Windows SDK automatically. To use Garmin's raw commands in the current PowerShell session, add its `bin` directory to `PATH`:

```powershell
$sdkRoot = (Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
$env:Path += ";$sdkRoot\bin"
Get-Command java, monkeyc, monkeydo, connectiq
```

### 2. Create or recover the signing key

All PRG files must be signed with a 4096-bit RSA developer key.

- If this app has already been published in the Connect IQ Store, copy the original developer key from the old laptop. Garmin requires that same key for Store updates.
- For personal side-loading, a new key is sufficient. In VS Code run `Monkey C: Generate a Developer Key`, choose a safe location outside this repository, and back it up.

Official key guidance: <https://developer.garmin.com/connect-iq/core-topics/security/>

### 3. Build and test in the simulator

The checked-in `bin\pacer.prg` and `publish\pacer.prg` are stale artifacts from the old laptop; they do **not** contain these settings or input changes. Build a new PRG before side-loading.

Open this repository's root folder in VS Code, open any `.mc` file, and press `Command+F5` on macOS (`Ctrl+F5` on Windows). Choose **vívoactive 5** when prompted. Exercise this checklist in the simulator:

1. The app pulses at the displayed interval.
2. The upper button opens **Pacer settings**.
3. Tapping the main screen does not open settings.
4. Each picker saves its value and the new pace takes effect immediately.
5. A right swipe on the main screen does not exit.
6. **Exit Pacer** closes the app.

On macOS, compile directly from the repository root after completing the PATH setup above:

```bash
mkdir -p bin
monkeyc -d vivoactive5 -f monkey.jungle -o bin/pacer-vivoactive5.prg -y "$HOME/path/to/developer_key.der"
```

Start the simulator in one Terminal window:

```bash
connectiq
```

Then load the binary from another Terminal window:

```bash
monkeydo bin/pacer-vivoactive5.prg vivoactive5
```

On macOS, the included `publish.sh` is the everyday path. It bumps the version
shown on the main screen, rebuilds, and copies the PRG to the watch when the
volume is mounted:

```bash
./publish.sh              # bump the patch version and build
./publish.sh --no-bump    # rebuild the current version unchanged
./publish.sh --set 0.20   # build as an explicit version
```

It resolves the active SDK from `current-sdk.cfg` on its own. The signing key
comes from `$PACER_DEVELOPER_KEY`, falling back to `~/Music/developer_key`.
Bumping every build is the point: after launching, check that the main screen
shows the version the script just printed. If it does not, the watch is still
running the old build.

On Windows, compile from PowerShell with the included script:

```powershell
.\build.ps1 -DeveloperKey "C:\keys\developer_key.der"
```

That produces `bin\pacer-vivoactive5.prg`. The equivalent raw Windows compiler command is:

```powershell
monkeyc -d vivoactive5 -f monkey.jungle -o bin\pacer-vivoactive5.prg -y C:\keys\developer_key.der
```

### 4. Build for and install on the watch

The simplest route is the command palette command `Monkey C: Build for Device`, followed by **vívoactive 5**. Connect the watch with a data-capable USB cable, copy the resulting PRG to `GARMIN\APPS`, safely eject the watch, and launch Pacer from its app list.

If a differently signed copy with the same app ID is already installed, remove that copy first. Removing it may also remove its stored settings.

Garmin's official first-app and side-loading guide is at <https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/>. For a Store release, use `Monkey C: Export Project` to create an IQ package rather than uploading a device-specific PRG.

## Reference implementation choices

- Persistent values use `Toybox.Application.Storage`: <https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html>
- The settings UI uses `WatchUi.Menu2` and `WatchUi.Picker`: <https://developer.garmin.com/connect-iq/core-topics/native-controls/>
- Garmin's maintained picker factory example: <https://github.com/garmin/connectiq-apps/blob/master/device-apps/bluetooth-mesh-sample/source/NumberFactory.mc>
- Input behavior follows `WatchUi.BehaviorDelegate`: <https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html>
- Garmin's forum discussion of the shared Back behavior: <https://forums.garmin.com/developer/connect-iq/i/bug-reports/bug-swipe-right-on-the-left-side-of-the-screen-triggers-onkey-key_esc>

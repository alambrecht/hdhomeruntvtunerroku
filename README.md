# HDHR TV — Live TV Player for HDHomeRun on Roku

![BrightScript](https://img.shields.io/badge/BrightScript-6F1AB1?logo=roku&logoColor=white)
![Roku SceneGraph](https://img.shields.io/badge/Roku-SceneGraph-6F1AB1)

HDHR TV is a minimal live-TV channel for an HDHomeRun tuner, built for sideloading on a Roku. It has a channel list and a full-screen player, with no guide, DVR or account.

The official HDHomeRun app finds tuners with local broadcast discovery, which doesn't cross VLANs or subnets. HDHR TV finds the tuner through SiliconDust's cloud discovery or a manually entered IP address, and talks to it only over plain HTTP, which routes normally between network segments.

---

## Features

- **Automatic Tuner Discovery** – Finds the HDHomeRun through `api.hdhomerun.com/discover`. If that fails, you can enter the IP by hand.
- **ATSC 1.0 Lineup** – Loads channels from the tuner's `lineup.json` and filters out ATSC 3.0 and DRM channels.
- **Live Playback** – Plays the tuner's MPEG-TS stream in the Roku `Video` node.
- **MPEG-2 Fallback** – If the Roku can't decode MPEG-2 and the tuner is an HDHomeRun EXTEND, MPEG-2 channels are transcoded to H.264 by the tuner (see [MPEG-2 Video](#mpeg-2-video)).
- **Remote-Friendly Controls** – Up/down and rewind/fast-forward channel surfing, and an on-demand channel banner.
- **Remembers the Tuner** – The tuner address is saved in the Roku registry.

---

## Tech Stack

- Language: BrightScript.
- UI: Roku SceneGraph (XML components), FHD (1920×1080) layout that Roku scales for HD devices.
- Playback: SceneGraph `Video` node (`streamFormat: ts`, `live: true`).
- Networking: `roUrlTransfer` in a `Task` node.
- Platform: Roku OS 10 or later (the tuner address dialog uses `StandardKeyboardDialog`).
- Build: `zip` and `curl` (no SDK needed).

---

## Quick Start

### Prerequisites

- A Roku with **developer mode** enabled (see below).
- An HDHomeRun reachable from the Roku on ports **80** (lineup) and **5004** (stream). If the Roku is on another VLAN or subnet, allow that traffic in your router or firewall.
- `zip` and `curl` on your computer. Pillow is needed only to redraw the images.

### Enable Developer Mode (once)

1. On the Roku remote press **Home ×3, Up ×2, Right, Left, Right, Left, Right**.
2. Note the IP address shown, accept the license, and set a developer password. The Roku reboots.

### Build and Sideload

```bash
./build.sh
# → out/hdhr-tv.zip

ROKU_IP=192.168.1.20 ROKU_PASS=<developer password> ./build.sh install
```

Or open `http://<roku-ip>` in a browser, sign in as `rokudev` with the developer password, and upload `out/hdhr-tv.zip`.

- A Roku holds one sideloaded channel at a time. Installing replaces it, and it stays installed across reboots.
- `./build.sh remove` uninstalls it. This also clears the saved tuner address.

The channel appears as **HDHR TV** at the end of the home screen's channel grid.

## Repository Structure

```bash
/HDHomerun Tuner for Roku
├── manifest                     # Title, version, icon and splash paths
├── /source
│   └── main.brs                 # Entry point: creates the scene
├── /components
│   ├── MainScene.xml/.brs       # Loading, screen switching, tuner address dialog
│   ├── HdhrTask.xml/.brs        # Tuner discovery, lineup.json parsing, MPEG-2 handling
│   ├── ChannelListScreen.xml/.brs  # Channel list and Tuner address button
│   ├── ChannelItem.xml/.brs     # One channel row
│   ├── PlayerScreen.xml/.brs    # Video node, channel switching, banner
│   └── Util.brs                 # URL normalization and JSON helpers
├── /images                      # Channel icon (FHD/HD) and splash screens
├── /tools/make_images.py        # Redraws /images
└── build.sh                     # Zip, sideload, remove
```

## Architecture Overview

**Scene (`MainScene`)**
- Reads the saved tuner address from the registry, or discovers it on first launch and saves it.
- Runs `HdhrTask` to load the lineup. If discovery or loading fails, it shows the error and the tuner address dialog.

**Lineup (`HdhrTask`)**
- Runs on a background thread, because SceneGraph doesn't allow network calls on the render thread.
- Uses a 5-second timeout for each request.

**Player (`PlayerScreen`)**
- Holds focus itself, so the `Video` node never handles keys and no trick-play UI appears.
- Waits 250 ms before tuning, so rapid channel presses skip channels without opening each stream.
- Stops the video when you leave the player, which closes the HTTP stream and frees the tuner.

### HDHomeRun Endpoints Used

| Endpoint | Method | Description |
|---|---|---|
| `https://api.hdhomerun.com/discover` | GET | Cloud discovery of tuners on your LAN |
| `http://<tuner>/lineup.json` | GET | Channel lineup |
| `http://<tuner>/discover.json` | GET | Tuner model, checked only when the Roku can't decode MPEG-2 |
| `http://<tuner>:5004/auto/v<channel>` | GET | Live MPEG-TS stream for a channel (uses one tuner) |

## Usage

| Remote button | Action |
|---|---|
| Up / Fast-forward | Next channel |
| Down / Rewind | Previous channel |
| OK | Show or hide the channel banner |
| Back | Return to the channel list (exits from the list) |
| `*` (on the list) | Tuner address |

Roku remotes have no number keys, so the Android app's direct number tuning isn't available.

To point the channel at a different tuner, use **Tuner address** on the channel list.

### MPEG-2 Video

Most ATSC 1.0 stations broadcast MPEG-2 video. The Nvidia Shield decodes it, but most Roku players don't. At load time the channel asks the Roku (`CanDecodeVideo`) and handles MPEG-2 channels like this:

| Roku decodes MPEG-2 | Tuner | Result |
|---|---|---|
| Yes | Any | Plays the original stream |
| No | HDHomeRun EXTEND (`HDTC-*`) | Requests `?transcode=heavy` (H.264 at the original resolution) |
| No | Other models | Tries anyway and shows *This Roku can't decode MPEG-2 video* in the banner |

H.264 channels always play the original stream. To use another EXTEND profile (`mobile`, `internet720`, `internet480`, …), change the suffix in `mpeg2Handling` in `HdhrTask.brs`.

### Audio

Broadcast audio is AC-3 (Dolby Digital). The Roku passes it through over HDMI when the TV or receiver supports it, or decodes it if the player can. Check **Settings > Audio** on the Roku if a channel has no sound.

## Testing

There are no automated tests. Test on a real Roku.

- The debug console shows BrightScript errors and `print` output: `telnet <roku-ip> 8085`.
- To test the tuner address dialog, use **Tuner address**, or run `./build.sh remove` before installing to clear the saved address.

## Versioning

Uses Semantic Versioning in `manifest` (`major_version`, `minor_version`, `build_version`). Bump it for each release.

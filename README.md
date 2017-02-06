# "Mac OS X Agent" for ManageEngine Asset Explorer

An installer for a scheduled version of [ManageEngine Asset Explorer][ae-website] script "`ae_scan_mac.sh`". This allows to inventory all Mac OS X devices on a regular basis.

## Features
* Runs via LaunchDaemon on an hourly basis
* Runs auto-update via LaunchDaemon on a weekly basis

## Options

| Option | Mandatory | Description |
|--------|-----------|-------------|
| -h | Yes | Hostname of the Service Desk or Asset Explorer (e.g. `servicedesk.test.com`) |
| -p | No | Port (default: `80`) |
| -s | No | Schema (default: `http`) |
| -i | No | Interval in seconds to run the script (default: `3600`)
| -u | No | Disables the installation of the weekly auto-updater |
| -r | No | Runs the uninstaller |

## How to install

```bash
curl -s https://raw.githubusercontent.com/hipages/manageengine/master/asset-explorer/ae_scan_mac_scheduled.sh | sudo bash -s -- -h servicedesk.mydomain.com
```

## How to Uninstall

```bash
curl -s https://raw.githubusercontent.com/hipages/manageengine/master/asset-explorer/ae_scan_mac_scheduled.sh | sudo bash -s -- -h servicedesk.mydomain.com -r
```

[ae-website]: https://www.manageengine.com/products/asset-explorer/

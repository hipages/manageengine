# "Mac OS X Agent" for ManageEngine Asset Explorer

Install a modified version of ManageEngine Asset Explorer's `ae_scan_mac.sh`
and runs it on a defined interval (default: 3600s) via LaunchDaemon.

## How to install

```bash
sudo bash <(curl -s https://raw.githubusercontent.com/hipages/manageengine/master/asset-explorer/ae_scan_mac_scheduled.sh) -h servicedesk.mydomain.com
```

# How to Uninstall

sudo bash <(curl -s https://gist.githubusercontent.com/estahn/93f3cd96dc652c87fa8ee94133aac0da/raw/fcdca2d9209869627abe37d8f8f6d357c8dfa425/ae_scan_mac.sh)


ae.sh --host servicedesk.corp.hipagesgroup.com.au

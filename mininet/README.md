# Mininet Config

## Installation

1. Download Mininet Ubuntu 20 VM [here](https://github.com/mininet/mininet/releases/tag/2.3.0).
2. Import it into Virtual Box using File > Import Appliance.
3. Start the VM and login using username: `mininet` with password: `mininet`.
4. Test installation using `sudo mn -h`.

Note: Sometimes the VM requires a restart to work for some reason.

## SSH into VM (Optional)

You may want to `ssh` into the VM from your PC's terminal for convenience.
You can accomplish this by using port forwarding on NAT via Adapter 2.

## Useful Commands

- Clean Mininet `sudo mn -c`

# Automated SDN Configuration with OpenDaylight

This repository provides automation scripts for configuring Software-Defined Networks (SDN) using OpenDaylight as the controller. The scripts automatically discover network topologies and configure flow rules to enable basic connectivity between hosts.

## Overview

The automation tool creates an SDN environment that provides basic L2 switching functionality through OpenFlow. It uses the NORMAL action to configure switches, which allows:

- ARP resolution for discovering network hosts
- IP packet forwarding for host-to-host communication
- Simplified flow table management

While less efficient than a purpose-built L2 switch, this configuration provides a solid starting point for SDN experimentation with minimal manual configuration.

## Dependencies

- `docker compose`: can be easily installed from [here](https://docs.docker.com/compose/install/linux/#install-using-the-repository) via the "Install using the repository" method.

## Usage

### Running the Automation

1. Start your OpenDaylight controller: `sudo docker compose up -d`.
2. Start Mininet with a 2-layer tree topology: `sudo mn --controller=remote,ip=<controller-ip>,port=6653 --topo tree,2 --switch ovsk,protocols=OpenFlow13`. The `<controller-ip>` can simply be set to `localhost`. This step will produce a `mininet>` console.
3. Open a second terminal and run the script using `./automate.sh`. You will be prompted for your controller IP address but since we are using `localhost`, you can simply select the default (`127.0.0.1`).
4. Test connectivity in the `mininet>` console: `pingall`.

### Managing flows

To clear all configured flows: `./clear_flows.sh`.
To exit the `mininet>` console: `exit`.

## How it Works

The `automate.sh` script performs the following operations:

1. Discovery Phase: Queries the OpenDaylight controller to discover all connected switches
2. Cleanup Phase: Removes any existing flow rules from the switches
3. Configuration Phase: Configures each switch with three essential flow rules:
   - ARP Handler (Priority 100): Processes ARP packets using normal L2 behavior
   - IP Handler (Priority 50): Processes IP packets using normal L2 behavior
   - Default Forward (Priority 1): Handles all other packet types

These rules use OpenFlow's "NORMAL" action, which instructs switches to process packets using their built-in L2/L3 forwarding mechanisms.

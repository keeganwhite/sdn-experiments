# Automated SDN Configuration with OpenDaylight

This repository provides automation scripts for configuring Software-Defined Networks (SDN) using OpenDaylight as the controller. The scripts automatically discover network topologies and configure flow rules to enable basic connectivity between hosts.

## Overview

The automation tool creates an SDN environment that provides basic L2 switching functionality through OpenFlow. It uses the NORMAL action to configure switches, which allows:

- ARP resolution for discovering network hosts
- IP packet forwarding for host-to-host communication
- Simplified flow table management

While less efficient than a purpose-built L2 switch, this configuration provides a solid starting point for SDN experimentation with minimal manual configuration.

## Usage

### Running the Automation

1. Start your OpenDaylight controller: `docker compose up -d`.
2. Start Mininet with a topology: `sudo mn --controller=remote,ip=<controller-ip>,port=6653 --topo tree,2 --switch ovsk,protocols=OpenFlow13`
3. Run the script using `./automate.sh` and enter your controller IP address.
4. Test connectivity in the Mininet console: `mininet> pingall`

### Managing flows

To clear all configured flows: `./clear_flows.sh`.

## How it Works

The `automate.sh` script performs the following operations:

1. Discovery Phase: Queries the OpenDaylight controller to discover all connected switches
2. Cleanup Phase: Removes any existing flow rules from the switches
3. Configuration Phase: Configures each switch with three essential flow rules:
   - ARP Handler (Priority 100): Processes ARP packets using normal L2 behavior
   - IP Handler (Priority 50): Processes IP packets using normal L2 behavior
   - Default Forward (Priority 1): Handles all other packet types

These rules use OpenFlow's "NORMAL" action, which instructs switches to process packets using their built-in L2/L3 forwarding mechanisms.

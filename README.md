# SDN Experiments

Repo containing SDN config and experiments

## Mininet

Set up Mininet following the instructions in [this README](./mininet/README.md).

## Opendaylight Controller

There are various Opendaylight (ODL) examples in this repo.

### Basic Example

To gain an understaning of basic Opendaylight configurations and how the switches work with flow entries follow the instructions in [this README](./opendaylight-basic/README.md).

### Automated Example

The [README file here](./opendaylight-automated/README.md) contains instructions on setting up an automated SDN that will forward packets no matter the topology. This is intended for usage with other applications/APIs but it will allow packets that do not hit a flow table entry to still be forwarded to their destination.

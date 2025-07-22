# Traffic Replay

## Description

Python scripts used to perform traffic replay.

- `pcap_anonymize.py` used for converting all public IP addresses to a specified value (default of "0.0.0.0") in a given `.pcap` file. Produces output `anonymized.pcap`.
- `pcap_replay.py` used for replaying a given `.pcap` file using `mininet`. Produces output `replayed.pcap` and displays bandwidth and latency.

## Dependencies

- `mininet`: we assume `mininet` VM is working environment.
- `python3.8-venv`: used to setup Python virtual environment.
- `tcpreplay`: used to process the `.pcap` files.
- `tshark`(Optional): used to display the processed `.pcap` files.

## Usage

1. Run `make`
2. Run `make anonymize`
3. Run `make replay`

When complete, run `make clean`.

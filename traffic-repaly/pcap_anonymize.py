# Python script to convert all public IP addresses in a given .pcap file to a specified address

from scapy.all import rdpcap, wrpcap, IP
import ipaddress


def is_public_ip(ip):
    # Determine if IP address is public or not
    ip_obj = ipaddress.ip_address(ip)
    return not (
        ip_obj.is_private
        or ip_obj.is_loopback
        or ip_obj.is_multicast
        or ip_obj.is_reserved
    )


def anonymize_pcap(input_pcap, output_pcap, new_ip):
    # Convert all public IP addresses in pcap to new_ip
    packets = rdpcap(input_pcap)
    for pkt in packets:
        if IP in pkt:
            # Replace public source IP with new_ip
            if is_public_ip(pkt[IP].src):
                pkt[IP].src = new_ip
            # Replace public destination IP with new_ip
            if is_public_ip(pkt[IP].dst):
                pkt[IP].dst = new_ip
            # Recompute checksum after change
            del pkt[IP].chksum
            if pkt.haslayer("TCP"):
                del pkt["TCP"].chksum
            if pkt.haslayer("UDP"):
                del pkt["UDP"].chksum
    wrpcap(output_pcap, packets)


def main():
    input_file = "example.pcap"
    output_file = "anonymized.pcap"
    new_ip = "0.0.0.0"
    anonymize_pcap(input_file, output_file, new_ip)


if __name__ == "__main__":
    main()

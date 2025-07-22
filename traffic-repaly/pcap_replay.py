# Python script to replay a given .pcap file using a mininet simulation for a simple topology

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.log import setLogLevel

import time


class SimpleTopo(Topo):
    # Build simple h1-s1-h2 topo
    def build(self):
        h1 = self.addHost("h1")
        h2 = self.addHost("h2")
        s1 = self.addSwitch("s1")
        self.addLink(h1, s1)
        self.addLink(h2, s1)


def replay_pcap(net, host, pcap_file, iface="h1-eth0"):
    # Run tcpreplay on 'host' to send packets from pcap_file over iface
    print("Starting tcp replay on host %s interface %s" % (host.name, iface))
    cmd = "tcpreplay --intf1={} {}".format(iface, pcap_file)
    host.cmd(cmd)


def run():
    # Start mininet
    topo = SimpleTopo()
    net = Mininet(topo=topo, controller=Controller)
    net.start()

    # Get hosts
    h1 = net.get("h1")
    h2 = net.get("h2")

    # Start tcpdump on h2 to capture packets arriving during replay
    print("Starting tcpdump on h2 to listen for packets")
    replayed_file = "replayed.pcap"
    h2.cmd("tcpdump -i h2-eth0 -w " + replayed_file + "&")

    # Replay pcap from h1 interface
    input_file = "anonymized.pcap"
    replay_pcap(net, h1, input_file, iface="h1-eth0")

    # Let replay run for a while (adjust sleep time as needed)
    time.sleep(10)

    # Stop tcpdump on h2
    h2.cmd("kill %tcpdump")
    print("You can now inspect " + replayed_file + " for replayed packets")

    # Calc latency
    net.pingAll()

    # Calc bandwidth
    net.iperf((net.get("h1"), net.get("h2")))

    # Display mininet terminal
    # CLI(net)

    # Stop mininet
    net.stop()


if __name__ == "__main__":
    setLogLevel("info")
    run()

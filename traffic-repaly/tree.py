from mininet.link import TCLink
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.log import setLogLevel, info
from mininet.cli import CLI
from mininet.node import OVSSwitch, Controller, RemoteController
from mininet.term import makeTerm
from time import sleep
import subprocess
import os

def start_wireshark(net, interface_name):
    print(f"Starting Wireshark on {interface_name}")
    subprocess.Popen(['sudo', 'wireshark', '-i', interface_name, '-k'])

def replay_pcap(host, pcap_file):
    # TODO make this replay independently with a script and not freeze
    interface = host.defaultIntf()
    tcpreplay_cmd = f"tcpreplay --intf1={interface} {pcap_file}"
    host.cmdPrint(tcpreplay_cmd)


def monitor_traffic(host, interface, output_file):
    tcpdump_cmd = f"tcpdump -i {interface} -w {output_file} &"
    host.cmdPrint(tcpdump_cmd)


class TreeTopo(Topo):
    """Tree topology with a fixed 'dumb_switch' and 'inet' host."""

    def build(self, num_switches, num_hosts):
        # Add the root switch (dumb_switch) and inet host
        dumb_switch = self.addSwitch('s0', protocols='OpenFlow13', dpid='0000000000000001')
        inet = self.addHost('inet', ip='10.0.0.2', mac=f"00:00:00:00:00:02")
        self.addLink(dumb_switch, inet, bw=10, cls=TCLink)

        # Create other switches and hosts in a tree topology
        switches = [dumb_switch]
        for i in range(1, num_switches + 1):
            dpid = f'{i + 1:016x}'
            switch = self.addSwitch(f's{i}', protocols='OpenFlow13', dpid=dpid)
            switches.append(switch)

        # Link switches in a tree structure
        for i in range(1, len(switches)):
            parent = switches[(i - 1) // 2]
            self.addLink(parent, switches[i], bw=2, cls=TCLink)

        # Add hosts and link them to switches
        for i in range(3, num_hosts + 3):
            host = self.addHost(f'h{i - 2}', ip=f'10.0.0.{i}', mac=f"00:00:00:00:00:{i:02x}")
            switch = switches[(i - 3) % num_switches + 1]
            self.addLink(switch, host, bw=2, cls=TCLink)


def run_simulation(num_switches, num_hosts):
    setLogLevel('info')

    topo = TreeTopo(num_switches=num_switches, num_hosts=num_hosts)
    c1 = RemoteController('c1', ip='127.0.0.1', port=2226)
    net = Mininet(topo=topo, controller=c1)
    net.start()
    info("*** Running interactive menu\n")
    user_input = "QUIT"
    while True:
        try:
            user_input = input("(C)LI / (Q)UIT / (S)IMULATE: ")
        except EOFError as error:
            user_input = "QUIT"

        if user_input.upper() == "CLI" or user_input.upper() == "C":
            info("Running CLI...\n")
            CLI(net)

        elif user_input.upper() == "QUIT" or user_input.upper() == "Q":
            info("Terminating...\n")
            net.stop()
            break
        elif user_input.upper() == "SIMULATE" or user_input.upper() == "S":
            inet_host = net.get('inet')

            for i in range(1, num_hosts + 1):
                host = net.get(f'h{i}')
                client_cmd = f"bash -c 'python replay_pcaps.py client {str(i)} {host.MAC()} ;'"
                internet_cmd = f"bash -c 'python replay_pcaps.py internet {str(i)} {inet_host.MAC()} ;'"
                print(client_cmd)
                print(internet_cmd)
                makeTerm(host, cmd=client_cmd)
                makeTerm(inet_host, cmd=internet_cmd)
        else:
            print("Command not found")



    # monitor_traffic(host, host.defaultIntf(), f'./tmp/host_{i}_traffic.pcap')



if __name__ == '__main__':
    num_switches = int(input("Enter the number of switches: "))
    num_hosts = int(input("Enter the number of hosts: "))
    run_simulation(num_switches, num_hosts)
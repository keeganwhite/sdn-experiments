from scapy.all import sendp, IP, UDP, Ether, TCP, rdpcap
from scapy.all import *
from scapy.sendrecv import sendpfast
import os
import sys
from dotenv import load_dotenv


def main():
    load_dotenv()  # Load environment variables from .env file
    node_type = str(sys.argv[1])
    node_number = str(sys.argv[2])
    mac_address = str(sys.argv[3])
    directory = os.getenv('PCAP_PARENT_DIRECTORY')
    if directory == 'update':
        print('Set your PCAP_PARENT_DIRECTORY environment variable')
        sys.exit(1)
    directory = f'{directory}/{node_type}_{node_number}/'
    csv_sent = str(mac_address) + ".csv"
    interface_name = "h" + node_number + "-eth0"
    if mac_address == '00:00:00:00:00:02':
        interface_name = 'inet-eth0'
    start_time_outer = time.time()
    for filename in os.listdir(directory):
        f = os.path.join(directory, filename)
        arr = send_pcap(f, interface_name)
        print(arr)
        key = arr[0]
        time_elapsed = arr[1]
        # try:
        #     with open(mac_address + "_sent_key.csv", 'a') as file:
        #         writer = csv.writer(file)
        #         filename_arr = filename.split(".")
        #         label = filename_arr[0]
        #         label = ''.join([i for i in label if not i.isdigit()])
        #         print(label)
        #         writer.writerow([label, key])
        # except Exception as e:
        #     print(e)
        end_time = time.time()
        if end_time - start_time_outer >= 60:
            break


def send_pcap(file_name, interface_name):
    """
    Sends PCAP file
    :param interface_name: interface to send via
    :param file_name: pcap tp send
    :return: array of key value generated from sending and the time taken to send
    """
    inethi_sample = rdpcap(file_name)
    for pkt in inethi_sample:
        if pkt.haslayer(IP) and pkt.haslayer(Raw) and not pkt.haslayer('TLS'):
            ip_src = pkt[IP].src
            ip_dst = pkt[IP].dst

            if pkt.haslayer(TCP):
                protocol = "TCP"
                sport = pkt[TCP].sport
                dport = pkt[TCP].dport
            elif pkt.haslayer(UDP):
                protocol = "UDP"
                sport = pkt[UDP].sport
                dport = pkt[UDP].dport

            if ip_src[:3] == "10.":
                key = ip_src + ip_dst + protocol + str(sport) + str(dport)
                break
            else:
                key = ip_dst + ip_src + protocol + str(dport) + str(sport)
                break
    try:
        start_time = time.time()
        sendpfast(inethi_sample, iface=interface_name, mbps=2)
        end_time = time.time()
        time_elapsed = end_time - start_time
        return [key, time_elapsed]
    except Exception as e:
        print(e)




if __name__ == "__main__":
    main()
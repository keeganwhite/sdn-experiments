# Makefile for python3 virtual env setup

venv/: requirements.txt
	python3 -m venv venv
	venv/bin/pip install -r requirements.txt

anonymize: venv/
	venv/bin/python pcap_anonymize.py
	tshark -r anonymized.pcap

replay: venv/
	sudo venv/bin/python pcap_replay.py
	tshark -r replayed.pcap

clean:
	rm -rf venv/
	rm -rf __pycache__

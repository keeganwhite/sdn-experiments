#!/bin/bash

# Create directory for flow entries if it doesn't exist
mkdir -p flow-entries

# Define function to create a flood entry JSON file
create_flood_json() {
    local switch=$1
    local port=$2
    local id=$3
    local file="flow-entries/flood_s${switch}_p${port}.json"
    
    cat > "$file" << EOF
{
  "flow": [
    {
      "table_id": 0,
      "id": "${id}",
      "priority": 4,
      "cookie": "4",
      "match": {
        "in-port": "openflow:${switch}:${port}"
      },
      "instructions": {
        "instruction": [
          {
            "order": 0,
            "apply-actions": {
              "action": [
                {
                  "order": 0,
                  "output-action": {
                    "output-node-connector": "FLOOD"
                  }
                }
              ]
            }
          }
        ]
      }
    }
  ]
}
EOF
    echo "Created $file"
}

# Define function to create a transfer entry JSON file
create_transfer_json() {
    local switch=$1
    local in_port=$2
    local out_port=$3
    local id=$4
    local file="flow-entries/transfer_s${switch}_p${in_port}_to_p${out_port}.json"
    
    cat > "$file" << EOF
{
  "flow": [
    {
      "table_id": 0,
      "id": "${id}",
      "priority": 4,
      "cookie": "4",
      "match": {
        "in-port": "openflow:${switch}:${in_port}"
      },
      "instructions": {
        "instruction": [
          {
            "order": 0,
            "apply-actions": {
              "action": [
                {
                  "order": 0,
                  "output-action": {
                    "output-node-connector": "${out_port}"
                  }
                }
              ]
            }
          }
        ]
      }
    }
  ]
}
EOF
    echo "Created $file"
}

# Create the JSON files for all required flows
# s1 transfer flows
create_transfer_json 1 1 2 "101"
create_transfer_json 1 2 1 "102"

# s2 flood flows
create_flood_json 2 1 "201"
create_flood_json 2 2 "202"
create_flood_json 2 3 "203"

# s3 flood flows
create_flood_json 3 1 "301"
create_flood_json 3 2 "302"
create_flood_json 3 3 "303"

# Prompt for controller's IP address
read -p "Enter the OpenDaylight controller's IP address: " IP_ADDRESS

echo "Using controller IP: $IP_ADDRESS"

# Upload flows to the switches
echo "Uploading flows to switch s1..."
curl -u admin:admin -X PUT \
  -d @flow-entries/transfer_s1_p1_to_p2.json \
  -H "Content-Type: application/json" \
  "http://${IP_ADDRESS}:8181/rests/data/opendaylight-inventory:nodes/node=openflow:1/flow-node-inventory:table=0/flow=101"

curl -u admin:admin -X PUT \
  -d @flow-entries/transfer_s1_p2_to_p1.json \
  -H "Content-Type: application/json" \
  "http://${IP_ADDRESS}:8181/rests/data/opendaylight-inventory:nodes/node=openflow:1/flow-node-inventory:table=0/flow=102"

echo "Uploading flows to switch s2..."
curl -u admin:admin -X PUT \
  -d @flow-entries/flood_s2_p1.json \
  -H "Content-Type: application/json" \
  "http://${IP_ADDRESS}:8181/rests/data/opendaylight-inventory:nodes/node=openflow:2/flow-node-inventory:table=0/flow=201"

curl -u admin:admin -X PUT \
  -d @flow-entries/flood_s2_p2.json \
  -H "Content-Type: application/json" \
  "http://${IP_ADDRESS}:8181/rests/data/opendaylight-inventory:nodes/node=openflow:2/flow-node-inventory:table=0/flow=202"

curl -u admin:admin -X PUT \
  -d @flow-entries/flood_s2_p3.json \
  -H "Content-Type: application/json" \
  "http://${IP_ADDRESS}:8181/rests/data/opendaylight-inventory:nodes/node=openflow:2/flow-node-inventory:table=0/flow=203"

echo "Uploading flows to switch s3..."
curl -u admin:admin -X PUT \
  -d @flow-entries/flood_s3_p1.json \
  -H "Content-Type: application/json" \
  "http://${IP_ADDRESS}:8181/rests/data/opendaylight-inventory:nodes/node=openflow:3/flow-node-inventory:table=0/flow=301"

curl -u admin:admin -X PUT \
  -d @flow-entries/flood_s3_p2.json \
  -H "Content-Type: application/json" \
  "http://${IP_ADDRESS}:8181/rests/data/opendaylight-inventory:nodes/node=openflow:3/flow-node-inventory:table=0/flow=302"

curl -u admin:admin -X PUT \
  -d @flow-entries/flood_s3_p3.json \
  -H "Content-Type: application/json" \
  "http://${IP_ADDRESS}:8181/rests/data/opendaylight-inventory:nodes/node=openflow:3/flow-node-inventory:table=0/flow=303"

echo "All flows have been uploaded. You can now try 'pingall' in Mininet."

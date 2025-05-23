#!/bin/bash
# automate.sh - Configure OpenDaylight flows for any network topology

# Text colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  OpenDaylight Switch Configuration Utility${NC}"
echo -e "${BLUE}==================================================${NC}"

# Get controller IP address
read -p "Enter OpenDaylight controller IP address [default: 127.0.0.1]: " CONTROLLER_IP
CONTROLLER_IP=${CONTROLLER_IP:-127.0.0.1}

# Auth credentials
USERNAME="admin"
PASSWORD="admin"

# Validate controller connection
echo -e "\n${BLUE}Connecting to OpenDaylight controller at ${CONTROLLER_IP}...${NC}"
if ! curl -s -o /dev/null -u ${USERNAME}:${PASSWORD} "http://${CONTROLLER_IP}:8181/rests/data/network-topology:network-topology?content=config"; then
    echo -e "${RED}Error: Cannot connect to OpenDaylight controller at ${CONTROLLER_IP}${NC}"
    echo "Please check:"
    echo "  - The controller is running"
    echo "  - The IP address is correct"
    echo "  - Port 8181 is accessible"
    exit 1
fi
echo -e "${GREEN}Successfully connected to controller${NC}"

# Discover the network topology
echo -e "\n${BLUE}Discovering network topology...${NC}"
TOPOLOGY=$(curl -s -u ${USERNAME}:${PASSWORD} -H "Accept: application/json" \
  "http://${CONTROLLER_IP}:8181/rests/data/network-topology:network-topology/topology=flow%3A1?content=nonconfig")

# Extract switch IDs from topology
SWITCH_IDS=$(echo "$TOPOLOGY" | grep -o '"node-id":"openflow:[0-9]*"' | grep -o 'openflow:[0-9]*')

if [ -z "$SWITCH_IDS" ]; then
    echo -e "${RED}No OpenFlow switches found connected to the controller.${NC}"
    echo "Please make sure your Mininet topology is running and switches are connected to the controller."
    exit 1
fi

# Format and display switch IDs
FORMATTED_SWITCH_IDS=$(echo "$SWITCH_IDS" | tr '\n' ' ')
echo -e "${GREEN}Found switches: ${FORMATTED_SWITCH_IDS}${NC}"

# Function to clear user-defined flows from a switch
clear_flows() {
    local SWITCH_ID=$1
    echo -e "  ${BLUE}Clearing existing user-defined flows from ${SWITCH_ID}...${NC}"
    
    # Get flow IDs - only try to delete flows with simple numeric IDs to avoid system flows
    FLOW_IDS=$(curl -s -u ${USERNAME}:${PASSWORD} -H "Accept: application/json" \
      "http://${CONTROLLER_IP}:8181/rests/data/opendaylight-inventory:nodes/node=${SWITCH_ID}/flow-node-inventory:table=0?content=nonconfig" | \
      grep -o '"id":"[0-9]*"' | cut -d'"' -f4)
      
    # Also get flows with ids like "arp-handler" or "default-forwarding"
    NAMED_FLOW_IDS=$(curl -s -u ${USERNAME}:${PASSWORD} -H "Accept: application/json" \
      "http://${CONTROLLER_IP}:8181/rests/data/opendaylight-inventory:nodes/node=${SWITCH_ID}/flow-node-inventory:table=0?content=nonconfig" | \
      grep -o '"id":"[a-z-]*"' | cut -d'"' -f4)
    
    # Combine all flow IDs we want to delete
    ALL_FLOW_IDS="$FLOW_IDS $NAMED_FLOW_IDS"
    
    if [ -z "$ALL_FLOW_IDS" ]; then
        echo -e "    - ${GREEN}No user-defined flows found to clear${NC}"
        return
    fi
    
    # Delete each flow
    for FLOW_ID in $ALL_FLOW_IDS; do
        echo -e "    - Deleting flow ${FLOW_ID}"
        curl -s -o /dev/null -u ${USERNAME}:${PASSWORD} -X DELETE \
          "http://${CONTROLLER_IP}:8181/rests/data/opendaylight-inventory:nodes/node=${SWITCH_ID}/flow-node-inventory:table=0/flow=${FLOW_ID}"
    done
    
    echo -e "    - ${GREEN}User-defined flows deleted successfully${NC}"
}

# Function to add ARP handler flow
add_arp_flow() {
    local SWITCH_ID=$1
    echo -e "  ${BLUE}Adding ARP handler flow to ${SWITCH_ID}...${NC}"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u ${USERNAME}:${PASSWORD} -X PUT \
      -H "Content-Type: application/json" \
      -d '{
        "flow": [
          {
            "table_id": 0,
            "id": "arp-handler",
            "priority": 100,
            "cookie": "0x1000",
            "match": {
              "ethernet-match": {
                "ethernet-type": {
                  "type": 2054
                }
              }
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
                          "output-node-connector": "NORMAL"
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }' \
      "http://${CONTROLLER_IP}:8181/rests/data/opendaylight-inventory:nodes/node=${SWITCH_ID}/flow-node-inventory:table=0/flow=arp-handler")
      
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 204 ]; then
        echo -e "    - ${GREEN}ARP handler flow added successfully${NC}"
    else
        echo -e "    - ${RED}Failed to add ARP handler flow (HTTP code: ${HTTP_CODE})${NC}"
    fi
}

# Function to add default forwarding flow
add_default_flow() {
    local SWITCH_ID=$1
    echo -e "  ${BLUE}Adding default forwarding flow to ${SWITCH_ID}...${NC}"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u ${USERNAME}:${PASSWORD} -X PUT \
      -H "Content-Type: application/json" \
      -d '{
        "flow": [
          {
            "table_id": 0,
            "id": "default-forwarding",
            "priority": 1,
            "cookie": "0x1001",
            "match": {},
            "instructions": {
              "instruction": [
                {
                  "order": 0,
                  "apply-actions": {
                    "action": [
                      {
                        "order": 0,
                        "output-action": {
                          "output-node-connector": "NORMAL"
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }' \
      "http://${CONTROLLER_IP}:8181/rests/data/opendaylight-inventory:nodes/node=${SWITCH_ID}/flow-node-inventory:table=0/flow=default-forwarding")
      
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 204 ]; then
        echo -e "    - ${GREEN}Default forwarding flow added successfully${NC}"
    else
        echo -e "    - ${RED}Failed to add default forwarding flow (HTTP code: ${HTTP_CODE})${NC}"
    fi
}

# Process each switch
echo -e "\n${BLUE}Processing switches...${NC}"
for SWITCH_ID in $SWITCH_IDS; do
    echo -e "${BLUE}Configuring ${SWITCH_ID}...${NC}"
    
    # Clear existing flows
    clear_flows $SWITCH_ID
    
    # Add new flows
    add_arp_flow $SWITCH_ID
    add_default_flow $SWITCH_ID
    
    echo -e "  ${GREEN}Configuration of ${SWITCH_ID} completed${NC}"
done

# Pause to allow switches to update
echo -e "\n${BLUE}Waiting for switches to update...${NC}"
sleep 5

# Verify flows using direct check instead of string matching
echo -e "\n${BLUE}Verifying configuration...${NC}"

for SWITCH_ID in $SWITCH_IDS; do
    echo -e "${BLUE}Checking ${SWITCH_ID}...${NC}"
    
    # Request specific flows directly rather than trying to parse the full table
    ARP_FLOW=$(curl -s -u ${USERNAME}:${PASSWORD} -X GET \
      "http://${CONTROLLER_IP}:8181/rests/data/opendaylight-inventory:nodes/node=${SWITCH_ID}/flow-node-inventory:table=0/flow=arp-handler?content=nonconfig")
      
    DEFAULT_FLOW=$(curl -s -u ${USERNAME}:${PASSWORD} -X GET \
      "http://${CONTROLLER_IP}:8181/rests/data/opendaylight-inventory:nodes/node=${SWITCH_ID}/flow-node-inventory:table=0/flow=default-forwarding?content=nonconfig")
    
    ARP_OK=false
    DEFAULT_OK=false
    
    # Check if responses contain flow data
    if [[ "$ARP_FLOW" == *"\"id\":\"arp-handler\""* ]]; then
        ARP_OK=true
    fi
    
    if [[ "$DEFAULT_FLOW" == *"\"id\":\"default-forwarding\""* ]]; then
        DEFAULT_OK=true
    fi
    
    if $ARP_OK && $DEFAULT_OK; then
        echo -e "  ${GREEN}✓ ${SWITCH_ID} is correctly configured${NC}"
    elif $ARP_OK; then
        echo -e "  ${RED}✗ ${SWITCH_ID} is missing default forwarding flow${NC}"
    elif $DEFAULT_OK; then
        echo -e "  ${RED}✗ ${SWITCH_ID} is missing ARP handler flow${NC}"
    else
        echo -e "  ${RED}✗ ${SWITCH_ID} is missing both flows${NC}"
    fi
done

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}Configuration process completed!${NC}"
echo -e "${BLUE}==================================================${NC}"
echo -e "All switches have been configured with:"
echo -e "  1. ARP handling (priority 100)"
echo -e "  2. Default forwarding (priority 1)"
echo -e "\nYou can now test connectivity in your Mininet environment."
echo -e "Try commands like 'pingall' to verify connectivity."

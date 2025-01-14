*** Settings ***
Documentation  Network stack stress tests using "nping" tool.

# This Suite has few testcases which uses nping with ICMP.
# ICMP creates a raw socket, which requires root privilege/sudo to run tests.

Resource                ../lib/resource.robot
Resource                ../lib/bmc_redfish_resource.robot
Resource                ../lib/ipmi_client.robot
Resource                ../lib/bmc_network_security_utils.robot

Library                 OperatingSystem
Library                 String
Library                 ../lib/gen_robot_valid.py
Library                 ../lib/bmc_network_utils.py
Library                 ../lib/ipmi_utils.py

Suite Setup             Suite Setup Execution

Force Tags              Network_Nping

*** Variables ***

${delay}                1000ms
${count}                4
${program_name}         nping
${iterations}           5000

*** Test Cases ***

Send ICMP Timestamp Request
    [Documentation]  Send ICMP packet type 13 and check BMC drops such packets
    [Tags]  Send_ICMP_Timestamp_Request

    # Send ICMP packet type 13 to BMC and check packet loss.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${count}  ${ICMP_PACKETS}  ${NETWORK_PORT}  ${ICMP_TIMESTAMP_REQUEST}
    Should Be Equal As Numbers  ${packet_loss}  100.00
    ...  msg=FAILURE: BMC is not dropping timestamp request messages.

Send ICMP Netmask Request
    [Documentation]  Send ICMP packet type 17 and check BMC drops such packets
    [Tags]  Send_ICMP_Netmask_Request

    # Send ICMP packet type 17 to BMC and check packet loss.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${count}  ${ICMP_PACKETS}  ${NETWORK_PORT}  ${ICMP_NETMASK_REQUEST}
    Should Be Equal As Numbers  ${packet_loss}  100.00
    ...  msg=FAILURE: BMC is not dropping netmask request messages.

Send Continuous ICMP Echo Request To BMC And Verify No Packet Loss
    [Documentation]  Send ICMP packet type 8 continuously and check no packets are dropped from BMC
    [Tags]  Send_Continuous_ICMP_Echo_Request_To_BMC_And_Verify_No_Packet_Loss

    # Send ICMP packet type 8 to BMC and check packet loss.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${iterations}  ${ICMP_PACKETS}
    Should Be Equal As Numbers  ${packet_loss}  0.0
    ...  msg=FAILURE: BMC is dropping packets.

Send Network Packets Continuously To Redfish Interface
    [Documentation]  Send network packets continuously to Redfish interface and verify stability.
    [Tags]  Send_Network_Packets_Continuously_To_Redfish_Interface

    # Send large number of packets to Redfish interface.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${iterations}  ${TCP_PACKETS}  ${REDFISH_INTERFACE}
    Should Be Equal As Numbers  ${packet_loss}  0.0
    ...  msg=FAILURE: BMC is dropping some packets.

    # Check if Redfish interface is functional.
    Redfish.Login
    Redfish.Logout


Send Network Packets Continuously To IPMI Port
    [Documentation]  Send network packets continuously to IPMI port and verify stability.
    [Tags]  Send_Network_Packets_Continuously_To_IPMI_Port

    # Send large number of packets to IPMI port.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${iterations}  ${TCP_PACKETS}  ${IPMI_PORT}
    Should Be Equal As Numbers  ${packet_loss}  0.0
    ...  msg=FAILURE: BMC is dropping some packets.

    # Check if IPMI interface is functional.
    Run IPMI Standard Command  chassis status


Send Network Packets Continuously To SSH Port
    [Documentation]  Send network packets continuously to SSH port and verify stability.
    [Tags]  Send_Network_Packets_Continuously_To_SSH_Port

    # Send large number of packets to SSH port.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${iterations}  ${TCP_PACKETS}  ${SSH_PORT}
    Should Be Equal As Numbers  ${packet_loss}  0.0
    ...  msg=FAILURE: BMC is dropping some packets.

    # Check if SSH interface is functional.

    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}


Flood Redfish Interface With Packets With Flags And Check Stability
    [Documentation]  Send large number of packets with flags to Redfish interface
    ... and check stability.
    [Tags]  Flood_Redfish_Interface_With_Packets_With_Flags_And_Check_Stability
    [Template]  Send Network Packets With Flags And Verify Stability

    # Target         No. Of packets  Interface              Flags

    # Flood syn packets and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${SYN_PACKETS}

    # Flood reset packets and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${RESET_PACKETS}

    # Flood fin packets and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${FIN_PACKETS}

    # Flood syn ack reset packets and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${SYN_ACK_RESET}

    # Flood packets with all flags and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${ALL_FLAGS}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Validate the setup.

    Valid Value  OPENBMC_HOST
    Valid Program  program_name


Verify Interface Stability
    [Documentation]  Verify interface is up and active.
    [Arguments]  ${port}

    # Description of argument(s):
    # port  Network port.

    Run Keyword If  ${port} == ${REDFISH_INTERFACE}
    ...  Redfish.Login
    ...  ELSE IF  ${port} == ${SSH_PORT}
    ...  Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ...  ELSE IF  ${port} == ${IPMI_PORT}
    ...  Run External IPMI Standard Command  lan print
    ...  ELSE IF  ${port} == ${HOST_SOL_PORT}
    ...  Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  port=${HOST_SOL_PORT}
    ...  ELSE
    ...  Redfish.Login

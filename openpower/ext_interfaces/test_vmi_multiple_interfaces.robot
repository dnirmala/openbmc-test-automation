*** Settings ***

Documentation    VMI multiple network interface tests.

# This includes test scenarios where VMI has multiple interfaces.
# So,assigns and verifies the combination of network mode in interfaces.

Resource         ../../lib/external_intf/vmi_utils.robot

Suite Setup       Suite Setup Execution
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Suite Teardown Execution

*** Variables ***

${test_ipv4_1}              10.6.6.6
${test_gateway_1}           10.6.6.1
${test_netmask_1}           255.255.252.0

${test_ipv4_2}              10.5.20.5
${test_gateway_2}           10.5.20.1
${test_netmask_2}           255.255.255.0
${test_ipv4_3}              10.6.4.6

*** Test Cases ***

Configure VMI Both Interfaces In Same Subnet And Verify
    [Documentation]  Configure VMI both interfaces in same subnet and verify.
    [Tags]  Configure_VMI_Both_Interfaces_In_Same_Subnet_And_Verify
    [Teardown]  Test Teardown Execution

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4_1}  ${test_gateway_1}
    ...  ${test_netmask_1}
    Set Static IPv4 Address To VMI And Verify  ${test_ipv4_3}  ${test_gateway_1}
    ...  ${test_netmask_1}  ${HTTP_ACCEPTED}  ${interface_list}[1]

Configure VMI Both Interfaces In Different Subnet And Verify
    [Documentation]  Configure VMI both interfaces in different subnet and verify.
    [Tags]  Configure_VMI_Both_Interfaces_In_Different_Subnet_And_Verify
    [Teardown]  Test Teardown Execution

    Set Static IPv4 Address To VMI And Verify  ${test_ipv4_1}  ${test_gateway_1}
    ...  ${test_netmask_1}
    Set Static IPv4 Address To VMI And Verify  ${test_ipv4_2}  ${test_gateway_2}
    ...  ${test_netmask_2}  ${HTTP_ACCEPTED}  ${interface_list}[1]

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution task.

    Redfish.Login
    Redfish Power On  stack_mode=skip  quiet=1
    Get Original Vmi Details


Test Teardown Execution
    [Documentation]  Do test teardown execution task.

    FOR  ${interface}  IN   @{interface_list}
        Delete VMI IPv4 Address  IPv4StaticAddresses  ${HTTP_ACCEPTED}  ${interface}
    END

    FFDC On Test Case Fail


Get Original Vmi Details
    [Documentation]  Get original details of VMI.

    @{interface_list}=  Get VMI Interfaces
    Set Suite Variable  @{interface_list}

    FOR  ${interface}  IN   @{interface_list}
        ${resp}=  Redfish.Get
        ...  /redfish/v1/Systems/hypervisor/EthernetInterfaces/${interface}
        ${ip_resp}=  Evaluate  json.loads(r'''${resp.text}''')  json
        ${length}=  Get Length  ${ip_resp["IPv4StaticAddresses"]}
        ${vmi_network_conf}=  Catenate  SEPARATOR=_   vmi_network_conf  ${interface}
        ${vmi_network_conf_value}=  Run Keyword If  ${length} != ${0}
        ...  Get VMI Network Interface Details  ${interface}
        Set Suite Variable  ${${vmi_network_conf}}  ${vmi_network_conf_value}
    END


Suite Teardown Execution
    [Documentation]  Do suite teardown execution task
    ...  Set original vmi details and verify.

    FOR  ${interface}  IN   @{interface_list}
        Run Keyword If  ${vmi_network_conf_${interface}} != ${None}
        ...  Set Static IPv4 Address To VMI And Verify
        ...  ${vmi_network_conf_${interface}}[IPv4_Address]
        ...  ${vmi_network_conf_${interface}}[IPv4_Gateway]
        ...  ${vmi_network_conf_${interface}}[IPv4_SubnetMask]
        ...  ${HTTP_ACCEPTED}  ${interface}
    END

    Redfish.Logout

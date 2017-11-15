#!/bin/bash
#
BRID=99
sudo ovs-vsctl del-br manage-br-${UID}
sudo ovs-vsctl del-br data-br-${UID}
sudo ovs-vsctl del-br vlan-br-${UID}

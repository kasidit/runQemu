#!/bin/bash
#
BRID=99
#
sudo ovs-vsctl add-br manage-br-${BRID}
sudo ovs-vsctl add-port manage-br-${BRID} managegw-${BRID} -- set interface managegw-${BRID} type=internal
sudo ovs-vsctl add-br data-br-${BRID}
sudo ovs-vsctl add-br vlan-br-${BRID}
#

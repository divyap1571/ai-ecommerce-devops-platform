#!/bin/bash

echo "================================="
echo " AI E-COMMERCE SYSTEM CHECK"
echo "================================="

echo ""
echo "Hostname:"
hostname

echo ""
echo "Current User:"
whoami

echo ""
echo "CPU:"
nproc

echo ""
echo "Memory:"
free -h

echo ""
echo "Disk:"
df -h /

echo ""
echo "Uptime:"
uptime

echo ""
echo "IP Address:"
hostname -I

echo ""
echo "================================="
echo "CHECK COMPLETED"
echo "================================="

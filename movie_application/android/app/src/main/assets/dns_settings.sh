#!/system/bin/sh

# Set Google DNS servers
settings put global dns_server 8.8.8.8
settings put global dns_server_2 8.8.4.4

# Flush DNS cache
ndc resolver flushdefaultif
ndc resolver setifdns eth0 "" 8.8.8.8 8.8.4.4
ndc resolver setdefaultif eth0 
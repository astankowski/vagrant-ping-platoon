#!/bin/bash
echo "Pinging 15 Vagrant nodes..."
echo "==========================="

for i in {1..15}; do
  IP="192.168.56.$((100+i))"
  
  # Sends 1 packet (-c 1) and times out after 1 second (-W 1)
  if ping -c 1 -W 1 "$IP" &> /dev/null; then
    printf "node%-2s (%s) : \e[32m[OK]\e[0m\n" "$i" "$IP"
  else
    printf "node%-2s (%s) : \e[31m[FAILED]\e[0m\n" "$i" "$IP"
  fi
done

echo "==========================="
echo "Test complete."

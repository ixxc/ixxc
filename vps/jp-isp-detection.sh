#!/bin/bash
# 原帖: https://www.nodeseek.com/post-156563-1

myipv4=$(curl -fsL ip.sb -4)
myipv6=$(curl -fsL ip.sb -6)
minsokukey=$(curl -fsL "https://minsoku.net/provider_detections" | grep 'gon.provider_detection_key' | sed -E 's/.*gon.provider_detection_key="([^"]+)".*/\1/')
curl -fsL "https://minsoku.net/api/utils/provider_detection?ipv4_ip=${myipv4}&ipv6_ip=${myipv6}&provider_detection_key=${minsokukey}"

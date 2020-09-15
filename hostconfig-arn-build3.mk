
DNS		?= $(shell nslookup google.com | grep Server | cut -f3)

#!/bin/bash
set -eux 
# Update the box
aptitude -y update
aptitude -y full-upgrade

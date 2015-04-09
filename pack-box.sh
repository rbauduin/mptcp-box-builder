#!/bin/bash

if [[ $# -lt 1 ]] ; then
	CFG=debian.json;
else
	CFG=$1;
fi

cd packer
packer build $CFG

Description
===========

These are scripts used to build vagrant mptcp enabled debian vagrant boxes.


Requirements
============

You need to have sudo access to run these script.

The scripts require apt-cacher-ng running on you machine, and debootstrap:

    sudo apt-get install apt-cacher-ng debootstrap

If this commands executes successfully, it probably means you have sudo setup correctly.

These scripts also use virtualboxi(https://www.virtualbox.org/) and packer (https://packer.io/).
Be sure to have packer executables in you path.

Running
=======

Boxes are built in 2 steps:

* build base system with dbootstrap, put it in a virtualbox, and export it as an appliance (.ova)
* use packer to build a vagrant box from the ova

The ova file generated at the first step can be reused to build multiple boxes.

To generate the .ova, just run 

    make ova

Once you have the ova, you can use it to build vagrant boxes thanks to packer.

Two example packer config files are available in the packer directory:

* debian.json will build a base debian box with an mptcp kernel
* mbdetect.json will build a box running mbdetect tests (https://github.com/rbauduin/mbdetect)


You can run the script pack-box.sh to build the box with the config file of your choice, eg:

    ./pack-box.sh debian.json

Build your base vagrant box with mptcp kernel by running

    make

Find your box in packer/box/mptcp.box

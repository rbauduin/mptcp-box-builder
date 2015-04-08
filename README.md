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

Build your base vagrant box with mptcp kernel by running
  make
Find your box at packer/box/mptcp.box

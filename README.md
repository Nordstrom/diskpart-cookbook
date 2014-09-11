Description
===========

This cookbook is a utility cookbook designed to make working with diskpart easier.  It implements a LWRP for
disk and provision.  This cookbook makes one LARGE assumption that must be accounted for if it is not true.  That
assumption is that you have 1 volume/partition per physical disk.  I would argue you always want this, but alas this
is the assumption foisted upon you by me!

When cloning this repository, clone into a directory named "diskpart" to have the provider names match those listed below.

ex: git clone https://github.com/moserke/diskpart-cookbook.git diskpart

Version
======

0.1.0 - This is at 0.1.0 currently because there is still extensive testing to be done against various versions of
windows.

Requirements
============

This only supports windows and depends on the windows cookbook from opscode.  This relies heavily on RegEx parsing
from the windows diskpart command.

A sleep was introduced into each of the actions because there are times with diskpart commands you need to give the OS a
chance to catch up before moving to the next command.  A great example of this is when you have a disk that is already
partitioned and formatted but is offline.  When bringing that disk online you must stall for a few seconds so the OS can
see the partition.  If you check immediately for a partition on that disk you will be told there is not one and then your create partition will fail.

Resource/Provider
=================

diskpart\_disk
------------------

### Actions

- :online: Brings the disk online (default)
- :convert: Converts to specified disk format
- :offline: Brings a disk offline

### Attribute Parameters

- :number: The disk number to operate on
- :type: The type of disk (:gpt, :mbr - default, :dynamic, :basic)
- :sleep: The amount of time to sleep after executing command (default is 1)

diskpart\_partition
------------------

### Actions

- :create: Create new primary partition (default)
- :format: Format partition
- :assign: Assign a drive letter to partition
- :extend: Extends the partition to all free space
- :create_primary: Creates a primary partition

### Attribute Parameters

- :disk_number: The disk number to operate on
- :align: The disk alignment (default is 1024)
- :fs: The type of file system (default is :ntfs)
- :letter: The drive letter to use
- :sleep: The amount of time to sleep after executing command (default is 1)
- :size: The size in Mb the partition will have (default is 1)


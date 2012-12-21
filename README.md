Description
===========

This cookbook is a utility cookbook designed to make working with diskpart easier.  It implements a LWRP for
disk and provision.  This cookbook makes one LARGE assumption that must be accounted for if it is not true.  That
assumption is that you have 1 volume/partition per physical disk.  I would argue you always want this, but alas this
is the assumption foisted upon you by me!

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

Partition Attributes
====================

```attribute :disk_number, :kind_of => Integer```
```attribute :align, :kind_of => Integer, :default => 1024```
```attribute :fs, :kind_of => Symbol, :default => :ntfs```
```attribute :letter, :kind_of => String, :name_attribute => true```
```attribute :sleep, :kind_of => Integer, :default => 1```

Disk Attributes
===============

```attribute :number, :kind_of => Integer```
```attribute :type, :kind_of => Symbol, :default => :mbr```
```attribute :sleep, :kind_of => Integer, :default => 1```

Partition Actions
=================

```actions :create, :format, :assign```
```default_action :create```

Disk Actions
============

```actions :online, :convert, :offline```
```default_action :online```

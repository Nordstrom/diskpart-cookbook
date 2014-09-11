#
# Author:: Kevin Moser (<kevin.moser@nordstrom.com>)
# Cookbook Name:: diskpart
# Resource:: partition
#
# Copyright:: 2012, Nordstrom, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

actions :create, :format, :assign, :extend, :create_primary

attribute :disk_number, :kind_of => Integer
attribute :volume_number, :kind_of => Integer
attribute :align, :kind_of => Integer, :default => 1024
attribute :fs, :kind_of => Symbol, :default => :ntfs
attribute :letter, :kind_of => String, :name_attribute => true
attribute :sleep, :kind_of => Integer, :default => 1
attribute :unit, :kind_of => Integer, :default => 4096
attribute :size, :kind_of => Integer, :default => 1

default_action :create

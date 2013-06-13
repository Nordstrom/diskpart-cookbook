#
# Author:: Kevin Moser (<kevin.moser@nordstrom.com>)
# Cookbook Name:: diskpart
# Provider:: disk
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
include Diskpart::Helper
include Windows::Helper
include Chef::Mixin::ShellOut

action :online do
  number = @new_resource.number
  updated = false

  unless online?(number)
    bring_online(number)
    sleep(@new_resource.sleep)
    updated = true
  end

  new_resource.updated_by_last_action(updated)
end

action :convert do
  number = @new_resource.number
  type = @new_resource.type
  updated = false

  disk_info = get_disk_info(number)

  # switch on the disk type to figure out what type
  # of disk conversion we are doing
  case type
  when :gpt
    unless disk_info[:gpt] == "*"
      convert_disk(number, "GPT")
      sleep(@new_resource.sleep)
      updated = true
    end
  when :mbr
    if disk_info[:gpt] == "*"
      convert_disk(number, "MBR")
      sleep(@new_resource.sleep)
      updated = true
    end
  when :basic
    if disk_info[:dyn] == "*"
      convert_disk(number, "BASIC")
      sleep(@new_resource.sleep)
      updated = true
    end
  when :dynamic
    unless disk_info[:dyn] == "*"
      convert_disk(number, "DYNAMIC")
      sleep(@new_resource.sleep)
      updated = true
    end
  end

  new_resource.updated_by_last_action(updated)
end

action :offline do
  number = @new_resource.number
  updated = false

  if online?(number)
    take_offline(number)
    sleep(@new_resource.sleep)
    updated = true
  end

  new_resource.updated_by_last_action(updated)
end

private
def online?(disk)
  @online ||= begin
    disk_info = get_disk_info(disk)
    disk_info[:status] == "Online"
  end
end

def clear_read_only(disk)
  Chef::Log.debug("Clearing Read-only on Disk #{disk}")
  setup_script("select disk #{disk}\nattributes disk clear readonly")
  cmd = shell_out(diskpart, { :returns => [0] })

  check_for_errors(cmd, "Disk attributes cleared successfully", true)
end

def convert_disk(disk, type)
  Chef::Log.debug("Converting Disk #{disk} to #{type}")
  setup_script("select disk #{disk}\nconvert #{type}")
  cmd = shell_out(diskpart, { :returns => [0] })

  check_for_errors(cmd, "DiskPart successfully converted the selected disk to #{type} format", true)
end

def bring_online(disk)
  clear_read_only(disk)

  Chef::Log.debug("Bringing Disk #{disk} online")
  setup_script("select disk #{disk}\nonline disk")
  cmd = shell_out(diskpart, { :returns => [0] })

  check_for_errors(cmd, "DiskPart successfully onlined the selected disk", true)
end

def take_offline(disk)
  Chef::Log.debug("Taking Disk #{disk} offline")
  setup_script("select disk #{disk}\noffline disk")
  cmd = shell_out(diskpart, { :returns => [0] })

  check_for_errors(cmd, "DiskPart successfully offlined the selected disk", true)
end

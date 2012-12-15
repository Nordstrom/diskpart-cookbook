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
include Windows::Helper
include Chef::Mixin::ShellOut

action :online do
  number = @new_resource.number
  unless online?(number)
    bring_online(number)
  end
end

action :convert do
  number = @new_resource.number
  type = @new_resource.type

  disk_info = get_disk_info(number)

  case type
  when :gpt
    unless disk_info[:gpt]
      convert_disk(number, "GPT")
    end
  when :mbr
    if disk_info[:gpt]
      convert_disk(number, "MBR")
    end
  when :basic
    if disk_info[:dyn]
      convert_disk(number, "BASIC")
    end
  when :dynamic
    unless disk_info[:dyn]
      convert_disk(number, "DYNAMIC")
    end
  end
end

action :offline do
  number = @new_resource.number
  if online?(number)
    take_offline(number)
  end
end

private
def online?(disk)
  @online ||= begin
    setup_script("list disk")
    cmd = shell_out("#{diskpart}", {:returns => [0]})
    check_for_errors(cmd, "Disk ###")
    cmd.stdout =~ /Disk #{disk}\s*Online/i
  end
end

def get_disk_info(disk)
  setup_script("list disk")
  cmd = shell_out("#{diskpart}", {:returns => [0]})
  check_for_errors(cmd, "Disk ###")

  disk_type = {}
  disk_type[:dyn] = (/Disk #{disk}\s*(Offline|Online)(\s*\d*.\w{2}\s*\d*.\w{2})(.{3}\*)/i =~ cmd.stdout)
  disk_type[:gpt] = (/Disk #{disk}\s*(Offline|Online)(\s*\d*.\w{2}\s*\d*.\w{2})(.{3}\*|.{4})(.{4}\*)/i =~ cmd.stdout)

  disk_type
end

def clear_read_only(disk)
  Chef::Log.debug("Bringing Disk #{disk} online")
  setup_script("select disk #{disk}\nattributes disk clear readonly")
  cmd = shell_out("#{diskpart}", {:returns => [0]})

  check_for_errors(cmd, "Disk attributes cleared successfully")
end

def convert_disk(disk, type)
  Chef::Log.debug("Converting Disk #{disk} to #{type}")
  setup_script("select disk #{disk}\nconvert #{type}")
  cmd = shell_out("#{diskpart}", {:returns => [0]})

  check_for_errors(cmd, "DiskPart successfully converted the selected disk to #{type} format")
end

def bring_online(disk)
  Chef::Log.debug("Bringing Disk #{disk} online")
  setup_script("select disk #{disk}\nonline disk")
  cmd = shell_out("#{diskpart}", {:returns => [0]})

  check_for_errors(cmd, "DiskPart successfully onlined the selected disk")

  clear_read_only(disk)
end

def take_offline(disk)
  Chef::Log.debug("Taking Disk #{disk} offline")
end

def check_for_errors(cmd, expected)
  unless cmd.stderr.empty?
    Chef::Application.fatal!(cmd.stderr)
  end

  unless cmd.stdout =~ /#{expected}/i
    Chef::Application.fatal!(cmd.stdout)
  end
end

def diskpart
  script_file = "#{Chef::Config[:file_cache_path]}/diskpart.script"

  @diskpart ||= begin
    "#{locate_sysnative_cmd("diskpart.exe")} /s #{script_file}"
  end
end

def setup_script(cmd)
  script_file = "#{Chef::Config[:file_cache_path]}/diskpart.script"
  
  ::File.delete(script_file) if ::File.exists?(script_file)
  ::File.open(script_file, 'w') do |script|
    script.write(cmd)
  end
end
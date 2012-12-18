#
# Author:: Kevin Moser (<kevin.moser@nordstrom.com>)
# Cookbook Name:: diskpart
# Provider:: partition
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

action :create do
  number = @new_resource.disk_number
  align = @new_resource.align
  updated = false

  unless exists?(number)
    create_partition(number, align)
    sleep(@new_resource.sleep)
    updated = true
  end

  @new_resource.updated_by_last_action(updated)
end

action :format do
  number = @new_resource.disk_number
  fs = @new_resource.fs
  updated = false

  unless formatted?(number)
    format(number, fs)
    sleep(@new_resource.sleep)
    updated = true
  end

  @new_resource.updated_by_last_action(updated)
end

action :assign do
  number = @new_resource.disk_number
  letter = @new_resource.letter
  updated = false

  letter = letter.gsub(":", "")
  letter = letter.gsub("/", "")
  letter = letter.gsub("\\", "")

  unless assigned?(number, letter)
    assign(number, letter)
    sleep(@new_resource.sleep)
    updated = true
  end

  @new_resource.updated_by_last_action(updated)
end

private

def exists?(disk)
  volume_info = get_volume_info(disk)
  !(volume_info[:volume].nil?)
end

def formatted?(disk)
  volume_info = get_volume_info(disk)
  !(volume_info[:fs] == "RAW")
end

def assigned?(disk, letter)
  volume_info = get_volume_info(disk)
  letter.downcase == volume_info[:letter].downcase
end

def create_partition(disk, align)
  Chef::Log.debug("Creating partition on Disk #{disk} aligned to #{align}")
  setup_script("select disk #{disk}\ncreate partition primary align=#{align}")
  cmd = shell_out("#{diskpart}", {:returns => [0]})
  check_for_errors(cmd, "DiskPart succeeded in creating the specified partition")
end

def format(disk, fs)
  volume_info = get_volume_info(disk)

  Chef::Log.debug("Formatting disk #{disk}, Volume #{volume_info[:volume_number]} with file system #{fs.to_s}")
  setup_script("select disk #{disk}\nselect volume #{volume_info[:volume_number]}\nformat fs=#{fs.to_s} quick")
  cmd = shell_out("#{diskpart}", {:returns => [0]})
  check_for_errors(cmd, "DiskPart successfully formatted the volume")
end

def assign(disk, letter)
  volume_info = get_volume_info(disk)

  Chef::Log.debug("Assigning letter #{letter} to disk #{disk}, volume #{volume_info[:volume_number]}")
  setup_script("select disk #{disk}\nselect volume #{volume_info[:volume_number]}\nassign letter=#{letter}")
  cmd = shell_out("#{diskpart}", {:returns => [0]})
  check_for_errors(cmd, "DiskPart successfully assigned the drive letter or mount point")
end

def get_volume_info(disk)
  setup_script("select disk #{disk}\ndetail disk")
  cmd = shell_out("#{diskpart}", {:returns => [0]})
  check_for_errors(cmd, "Disk ID:")
  /(?<volume>Volume\s(?<volume_number>\d{1,3}))\s{2,4}(?<letter>\s{3}|\s\w\s)\s{2}(?<label>.{0,11})\s{2}(?<fs>RAW|FAT|FAT32|exFAT|NTFS)\s{2,4}/i =~ cmd.stdout

  info = {}
  info =
  {
    :volume => volume.nil? ? nil : volume.rstrip.lstrip,
    :volume_number => volume_number.nil? ? nil : volume_number.rstrip.lstrip,
    :letter => letter.nil? ? nil : letter.rstrip.lstrip,
    :label => label.nil? ? nil : label.rstrip.lstrip,
    :fs => fs.nil? ? nil : fs.rstrip.lstrip
  }

  return info
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

  "#{locate_sysnative_cmd("diskpart.exe")} /s #{script_file}"
end

def setup_script(cmd)
  script_file = "#{Chef::Config[:file_cache_path]}/diskpart.script"
  
  ::File.delete(script_file) if ::File.exists?(script_file)
  ::File.open(script_file, 'w') do |script|
    script.write(cmd)
    script.write("\nexit")
  end
end
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
include Diskpart::Helper
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

  new_resource.updated_by_last_action(updated)
end

action :create_primary do
  disk = @new_resource.disk_number
  align = @new_resource.align
  letter = @new_resource.letter
  size = @new_resource.size

  Chef::Log.info "checking drive info"

  drive_info = get_drive_info(letter)

  Chef::Log.info "#{letter} drive info: volume => #{drive_info[:volume]}, size => #{drive_info[:size]}"

  updated = false

  unless drive_info[:size] == size
    unless drive_info[:volume].nil?
      delete_volume(drive_info[:volume])
    end

    Chef::Log.info "Creating drive #{letter} in disk #{disk} with size #{size}GB"

    size_in_mb = size * 1024
    create_primary_partition(disk, letter, size_in_mb, align)

    sleep(@new_resource.sleep)

    updated = true
  end

  new_resource.updated_by_last_action(updated)
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

  new_resource.updated_by_last_action(updated)
end

action :assign do
  number = @new_resource.disk_number
  letter = @new_resource.letter
  updated = false

  letter = letter[0]

  unless assigned?(number, letter)
    assign(number, letter)
    sleep(@new_resource.sleep)
    updated = true
  end

  new_resource.updated_by_last_action(updated)
end

action :extend do
  Chef::Log.debug "extend: disk number = #{new_resource.disk_number}, volume number = #{new_resource.volume_number}"
  number = new_resource.disk_number
  updated = false

  if has_free_space?(number)
    extend_volume(number)
    updated = true
  end

  new_resource.updated_by_last_action(updated)
end

private

CONVERSION_FACTOR = {
  GB: 1,
  MB: 1024,
  KB: 1024*1024
}

def exists?(disk)
  volume_info = get_volume_info(disk)
  !(volume_info[:volume].nil?)
end

def formatted?(disk)
  volume_info = get_volume_info(disk)
  !(volume_info[:fs] == 'RAW')
end

def assigned?(disk, letter)
  volume_info = get_volume_info(disk)
  letter.downcase == volume_info[:letter].downcase
end

def has_free_space?(disk)
  volume_info = get_volume_info(disk)
  Chef::Log.debug "volume_info: #{volume_info}"
  free_space, units = volume_info[:disk][:free].split(' ')
  free_space.to_i > 0 && !(units == 'KB' || units == 'B')
end

def create_partition(disk, align)
  Chef::Log.debug("Creating partition on Disk #{disk} aligned to #{align}")
  setup_script("select disk #{disk}\ncreate partition primary align=#{align}")
  cmd = shell_out(diskpart, { :returns => [0] })
  check_for_errors(cmd, 'DiskPart succeeded in creating the specified partition', true)
end

def create_primary_partition(disk, letter, size, align)
  Chef::Log.debug("Creating partition #{letter} on Disk #{disk} with size #{size} and align #{align}")
  setup_script("select disk #{disk}\ncreate partition primary size=#{size} align=#{align}\nformat quick\nassign letter #{letter}")
  cmd = shell_out(diskpart, { :returns => [0] })
  check_for_errors(cmd, 'DiskPart succeeded in creating the specified partition', true)
end

def delete_volume(volume)
  Chef::Log.debug("Deleting volume #{volume}")
  setup_script("select volume #{volume}\ndelete volume override")
  cmd = shell_out(diskpart, { :returns => [0] })
  check_for_errors(cmd, 'DiskPart successfully deleted the selected volume.', true)
end

def format(disk, fs)
  volume_number = new_resource.volume_number ||
    get_volume_info(disk)[:volume_number]

  Chef::Log.debug("Formatting disk #{disk}, Volume #{volume_number} with file system #{fs.to_s}")
  setup_script("select disk #{disk}\nselect volume #{volume_number}\nformat fs=#{fs.to_s} quick")
  cmd = shell_out(diskpart, { :returns => [0] })
  check_for_errors(cmd, 'DiskPart successfully formatted the volume', true)
end

def assign(disk, letter)
  volume_number = new_resource.volume_number ||
    get_volume_info(disk)[:volume_number]

  Chef::Log.debug("Assigning letter #{letter} to disk #{disk}, volume #{volume_number}")
  setup_script("select disk #{disk}\nselect volume #{volume_number}\nassign letter=#{letter}")
  cmd = shell_out(diskpart, { :returns => [0] })
  check_for_errors(cmd, 'DiskPart successfully assigned the drive letter or mount point', true)
end

def touch_volume(letter)
  Chef::Log.debug("Touching new volume #{letter} to force correct permissions...")
  ::Dir.mkdir("#{letter}:\\supersecretfix")
end

def extend_volume(disk)
  volume_number = new_resource.volume_number ||
    get_volume_info(disk)[:volume_number]

  Chef::Log.debug("Extending disk #{disk}, volume #{volume_number}")
  setup_script("select disk #{disk}\nselect volume #{volume_number}\nextend")
  cmd = shell_out(diskpart, { :returns => [0] })
  check_for_errors(cmd, 'DiskPart successfully extended the volume', true)
end

def get_volume_info(disk)
  setup_script("select disk #{disk}\ndetail disk")
  cmd = shell_out(diskpart, { :returns => [0] })
  check_for_errors(cmd, 'Disk ID:', true)
  /(?<volume>Volume\s(?<volume_number>\d{1,3}))\s{2,4}(?<letter>\s{3}|\s\w\s)\s{2}(?<label>.{0,11})\s{2}(?<fs>RAW|FAT|FAT32|exFAT|NTFS)\s{2,4}/i =~ cmd.stdout

  info = {}
  info =
    {
      :volume => volume.nil? ? nil : volume.rstrip.lstrip,
      :volume_number => volume_number.nil? ? nil : volume_number.rstrip.lstrip,
      :letter => letter.nil? ? nil : letter.rstrip.lstrip,
      :label => label.nil? ? nil : label.rstrip.lstrip,
      :fs => fs.nil? ? nil : fs.rstrip.lstrip,
      :disk => get_disk_info(disk)
    }

  info
end

def size_in_gb(size, magnitude)
  return nil if size.nil?
  size.to_i / CONVERSION_FACTOR[magnitude.to_sym]
end

def extract_info(matched_info)
  volume, size, magnitude = matched_info.captures

  Chef::Log.info "Existing volume #{volume} found with size #{size} #{magnitude}"

  {
    volume: volume.nil? ? nil : volume.rstrip.lstrip,
    size: size_in_gb(size, magnitude) ,
  }
end

def get_drive_info(letter)
  setup_script("list volume")
  cmd = shell_out(diskpart, {:returns => [0]})
  check_for_errors(cmd, 'Volume ', true)

  matched_info = cmd.stdout.match(/Volume\s(?<volume>\d){1,3}\s*#{letter}(\s\w\s|\s*)\w*\s*\w*\s*(?<size>\w*)\s(?<magnitude>MB|GB)/)

  matched_info.nil? ? {volume: nil, size: nil} : extract_info(matched_info)
end
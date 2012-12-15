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
end

action :format do
end

action :assign do
end

private
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
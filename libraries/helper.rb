#
# Author:: Kevin Moser (<kevin.moser@nordstrom.com>)
# Cookbook Name:: diskpart
# Library:: helper
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

module Diskpart
  module Helper
    def get_disk_info(disk)
      setup_script("list disk")
      cmd = shell_out(diskpart, { :returns => [0] })
      check_for_errors(cmd, "Disk ###", true)
      info_line = cmd.stdout.scan(/Disk #{disk}.*/i)
      info_line = info_line.first.gsub("\t", " ")
      /(?<name>.{8})\s{2}(?<status>.{13})\s{2}(?<size>.{7})\s{2}(?<free>.{7})\s{2}(?<dyn>(\s{3}|\s\*\s))\s{2}(?<gpt>(\s{3}|\s\*\s))/i =~ info_line unless info_line.nil?

      info = {}
      info =
        {
          :name => name.nil? ? nil : name.rstrip.lstrip,
          :status => status.nil? ? nil : status.rstrip.lstrip,
          :size => size.nil? ? nil : size.rstrip.lstrip,
          :free => free.nil? ? nil : free.rstrip.lstrip,
          :dyn => dyn.nil? ? nil : dyn.rstrip.lstrip,
          :gpt => gpt.nil? ? nil : gpt.rstrip.lstrip
        }

      info
    end

    def check_for_errors(cmd, expected, log = false)
      Chef::Log.debug("Output from command:\nstdout: #{cmd.stdout}\nstderr: #{cmd.stderr}") if log

      unless cmd.stderr.empty?
        Chef::Application.fatal!(cmd.stderr)
      end

      unless cmd.stdout =~ /#{expected}/i
        Chef::Application.fatal!(cmd.stdout)
      end
    end

    def diskpart
      @diskpart ||= begin
        "#{locate_sysnative_cmd("diskpart.exe")} /s #{script_file}"
      end
    end

    def setup_script(cmd)
      # Diskpart scripting requires an input script file.  We need to
      # check to see if it already exists from our last command and
      # delete it if it does before writing the new commands
      ::File.delete(script_file) if ::File.exists?(script_file)
      ::File.open(script_file, 'w') do |script|
        script.write(cmd)
        script.write("\nexit")
      end
    end

    def script_file
      @script_file ||= "#{Chef::Config[:file_cache_path]}/diskpart.script"
    end
  end
end

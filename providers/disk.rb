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

action :offline do
  number = @new_resource.number
  if online?(number)
    take_offline(number)
  end
end

private
def online?(disk)
end

def bring_online(disk)
end

def take_offline(disk)
end
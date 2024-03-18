#!/usr/bin/env ruby
$:.insert(0, File.join(ENV.fetch('WORKSPACE'), '/vpsadmin/vpsadmin/api/lib'))
$:.insert(1, File.join(ENV.fetch('WORKSPACE'), '/haveapi/haveapi/servers/ruby/lib'))

require 'bundler/setup'
require 'vpsadmin'
require 'pry'

VpsAdmin::API.default.start!
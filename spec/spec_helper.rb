require 'rspec-puppet'
require 'puppetlabs_spec_helper/puppet_spec_helper'
# require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |config|
  config.mock_with :rspec
end

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

WheezyFacts = { :osfamily => 'Debian',
                :operatingsystem => 'Debian',
                :operatingsystemrelease => 'wheezy',
                :lsbdistcodename => 'wheezy',
                :lsbdistid => 'debian',
                 # for concat/manifests/init.pp:193
                :id => 'id',
                :concat_basedir => '/opt/concat',
                :path => '/path',
                :ipaddress  => '192.168.192.168',
                :fqdn       => 'fully.qualified.domain.com',
                :hostname   => 'fully'
                }

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.environmentpath = File.join(Dir.pwd, 'spec')
end

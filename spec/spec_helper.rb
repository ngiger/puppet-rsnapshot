require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

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

# TODO: Hope this bugs gets squashed wit a new version of rspec
# needed if  bundle exec rspec spec/classes/ fails, but each spec/*.spec is okay when run alone
# see https://github.com/rodjek/rspec-puppet/issues/215
module RSpec::Puppet
  module Support
    def build_catalog(*args)
      @@cache[args] = self.build_catalog_without_cache(*args)
    end
  end
end
RSpec.configure do |c|
  c.hiera_config  = File.join(fixture_path, 'hiera/hiera.yaml')
  c.module_path   = File.join(fixture_path, 'modules')
  c.manifest_dir  = File.join(fixture_path, 'manifests')
end
at_exit { RSpec::Puppet::Coverage.report! }

require 'spec_helper'
require 'shared-examples'
manifest = 'fuel_pkgs/setup_repositories.pp'

describe manifest do
  shared_examples 'catalog' do

    if Noop.hiera_structure('repo_data/repo_type', false)
      repo_type    = Noop.hiera_structure('repo_data/repo_type')
      uca_repo_url = Noop.hiera_structure('repo_data/uca_repo_url')
      os_release   = Noop.hiera_structure('repo_data/uca_openstack_release')
      pin_haproxy  = Noop.hiera_structure('repo_data/pin_haproxy')
      pin_rabbitmq = Noop.hiera_structure('repo_data/pin_rabbitmq')
      pin_ceph  = Noop.hiera_structure('repo_data/pin_ceph')
    else
      repo_type = 'fuel'
    end

    before(:each) do
      Noop.puppet_function_load :generate_apt_pins
      MockFunction.new(:generate_apt_pins) do |function|
        allow(function).to receive(:call).and_return({})
      end
    end

    it 'apt-get should allow unathenticated packages' do
      should contain_apt__conf('allow-unathenticated').with_content('APT::Get::AllowUnauthenticated 1;')
    end

    it 'apt-get shouldn\'t install recommended packages' do
      should contain_apt__conf('install-recommends').with_content('APT::Install-Recommends "false";')
    end

    it 'apt-get shouldn\'t install suggested packages' do
      should contain_apt__conf('install-suggests').with_content('APT::Install-Suggests "false";')
    end

    if repo_type != 'fuel'
      it 'uca repository should be configured' do
         should contain_apt__source('UCA').with({
           location => uca_repo_url,
         })
      end
   end
  end
  test_ubuntu manifest
end
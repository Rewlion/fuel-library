# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute-vmware
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
# ROLE: base-os
# FACTS: centos7 ubuntu16
require 'spec_helper'
require 'shared-examples'
manifest = 'cgroups/cgroups.pp'

describe manifest do
  shared_examples 'catalog' do
    cgroups_config = Noop.hiera_hash 'cgroups', {}

    cgroups_settings = Noop.puppet_function(
      'prepare_cgroups_hash',
      cgroups_config
    )

    unless cgroups_settings.empty?
      it 'should declare cgroups class correctly' do
        should contain_class('cgroups').with(
          'cgroups_set'  => cgroups_settings,
        )
      end
    end

  end
  test_ubuntu_and_centos manifest
end

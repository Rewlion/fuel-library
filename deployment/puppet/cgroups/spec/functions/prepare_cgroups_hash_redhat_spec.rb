require 'spec_helper'

describe 'prepare_cgroups_hash' do
  it 'should exist' do
    is_expected.not_to be_nil
  end

  before(:each) do
    Facter.clear
    Facter.stubs(:fact).with(:memorysize_mb).returns Facter.add(:memorysize_mb) { setcode { 1024 } } 
    Facter.stubs(:fact).with(:osfamily).returns Facter.add(:osfamily) { setcode { 'RedHat' } }
  end

   context 'wrong JSON format' do
    let(:params) do
      {
        'apache' => '{{"CPUShares":1200}'
      }
    end

    it 'should raise if settings have wrong JSON format' do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'should not parse a data with type different from Hash' do
    let(:params) do
      'cinder-api:{"TasksMax":500, "MemoryLimit":"1G"}'
    end

    it 'should raise if group option is not a Hash' do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context "should not parse a data with property value's type different from string,int" do
    let(:params) do
      {
        'cinder-api' => '{"TasksMax":[500,1]}'
      }
    end

    it 'should raise if property value is an array' do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  ###########################
  context 'CPUAccounting with bool value' do
    let(:params) do
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder-api' => '{"CPUAccounting" : "true"}'
      }
    end

    let(:result) do
      {
        'cinder-api' => { 'CPUAccounting' => 'true' }
      }
    end

    it 'should parse valid hash' do
      is_expected.to run.with_params(params).and_return(result)
    end
  end

  context 'CPUAccounting with int value' do
    let(:params) do
      {
        'cinder-api' => '{"CPUAccounting":"200"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'CPUShares with valid value' do
    let(:params) do
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder-api' => '{"CPUShares" : "300"}'
      }
    end

    let(:result) do
      {
        'cinder-api' => { 'CPUShares' => '300' }
      }
    end

    it 'should parse valid hash' do
      is_expected.to run.with_params(params).and_return(result)
    end
  end

  context 'CPUShares with invalid value' do
    let(:params) do
      {
        'cinder-api' => '{"CPUShares":"FOO"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'CPUShares with invalid value(lover min)' do
    let(:params) do
      {
        'cinder-api' => '{"CPUShares":"1"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'CPUShares with invalid value(bigger max)' do
    let(:params) do
      {
        'cinder-api' => '{"CPUShares":"300000"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'CPUQuota with valid value' do
    let(:params) do
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder-api' => '{"CPUQuota" : "50%"}'
      }
    end

    let(:result) do
      {
        'cinder-api' => { 'CPUQuota' => '50%' }
      }
    end

    it 'should parse valid hash' do
      is_expected.to run.with_params(params).and_return(result)
    end
  end

  context 'CPUQuota with valid value' do
    let(:params) do
      {
        'cinder-api' => '{"CPUQuota":"200"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'MemoryLimit with valid value' do
    let(:params) do
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder-api' => '{"MemoryLimit" : "1024M"}'
      }
    end

    let(:result) do
      {
        'cinder-api' => { 'MemoryLimit' => '1024M' }
      }
    end

    it 'should parse valid hash' do
      is_expected.to run.with_params(params).and_return(result)
    end
  end

  context 'MemoryLimit with invalid value' do
    let(:params) do
      {
        'cinder-api' => '{"MemoryLimit":"200FOO"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'TasksMax with valid value' do
    let(:params) do
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder-api' => '{"TasksMax" : "22"}'
      }
    end

    let(:result) do
      {
        'cinder-api' => { 'TasksMax' => '22' }
      }
    end

    it 'should parse valid hash' do
      is_expected.to run.with_params(params).and_return(result)
    end
  end

  context 'TasksMax with invalid value' do
    let(:params) do
      {
        'cinder-api' => '{"TasksMax":"FOO"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'BlockIODeviceWeight with valid value' do
    let(:params) do
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder-api' => '{"BlockIODeviceWeight" : "/dev/sda1 10"}'
      }
    end

    let(:result) do
      {
        'cinder-api' => { 'BlockIODeviceWeight' => '/dev/sda1 10' }
      }
    end

    it 'should parse valid hash' do
      is_expected.to run.with_params(params).and_return(result)
    end
  end

  context 'BlockIODeviceWeight with invalid value by syntax' do
    let(:params) do
      {
        'cinder-api' => '{"BlockIODeviceWeight":"foo"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'BlockIODeviceWeight with invalid value( > 1k )' do
    let(:params) do
      {
        'cinder-api' => '{"BlockIODeviceWeight":"1000000"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'BlockIODeviceWeight with invalid value( < 10 )' do
    let(:params) do
      {
        'cinder-api' => '{"BlockIODeviceWeight":"0"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'BlockIOReadBandwidth with valid value' do
    let(:params) do
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder-api' => '{"BlockIOReadBandwidth" : "/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 5M"}'
      }
    end

    let(:result) do
      {
        'cinder-api' => { 'BlockIOReadBandwidth' => '/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 5M' }
      }
    end

    it 'should parse valid hash' do
      is_expected.to run.with_params(params).and_return(result)
    end
  end

  context 'BlockIOReadBandwidth with invalid value' do
    let(:params) do
      {
        'cinder-api' => '{"CPUAccounting":"foo"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'DeviceAllow with valid value' do
    let(:params) do
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder-api' => '{"DeviceAllow" : "/dev/sdb1 r"}'
      }
    end

    let(:result) do
      {
        'cinder-api' => { 'DeviceAllow' => '/dev/sdb1 r' }
      }
    end

    it 'should parse valid hash' do
      is_expected.to run.with_params(params).and_return(result)
    end
  end

  context 'DevicePolicy with valid value' do
    let(:params) do
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder-api' => '{"DevicePolicy" : "strict"}'
      }
    end

    let(:result) do
      {
        'cinder-api' => { 'DevicePolicy' => 'strict' }
      }
    end

    it 'should parse valid hash' do
      is_expected.to run.with_params(params).and_return(result)
    end
  end

  context 'DevicePolicy with invalid value' do
    let(:params) do
      {
        'cinder-api' => '{"DevicePolicy" : "FOO"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end

  context 'Unknown property' do
    let(:params) do
      {
        'cinder-api' => '{"UNKNOWN" : "FOO"}'
      }
    end

    it do
      is_expected.to run.with_params(params).and_raise_error(RuntimeError)
    end
  end
end

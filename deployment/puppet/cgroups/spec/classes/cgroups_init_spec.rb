require 'spec_helper'

describe 'cgroups', :type => :class do
  context "on a Debian OS" do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
      }
    end

    let :file_defaults do
      {
        :ensure  => :file,
        :owner   => 'root',
        :group   => 'root',
        :mode    => '0644',
        :tag     => 'cgroups',
      }
    end

    let (:params) {{ :cgroups_set => {} }}

    it { is_expected.to compile }
    it {
      should contain_class('cgroups::service').with(
        :cgroups_settings => params[:cgroups_set])
    }

    %w(libcgroup1 cgroup-bin cgroup-upstart).each do |cg_pkg|
      it { is_expected.to contain_package(cg_pkg) }
    end

    %w(/etc/cgconfig.conf /etc/cgrules.conf).each do |cg_file|
      it { is_expected.to contain_file(cg_file).with(file_defaults) }
      it { p catalogue.resource 'file', cg_file }
    end

    it { is_expected.to contain_file('/etc/cgrules.conf').that_notifies('Service[cgrulesengd]') }
    it { is_expected.to contain_file('/etc/cgconfig.conf').that_notifies('Service[cgconfigparser]') }
  end

  context 'On RedHat' do
    let (:facts) do
      {
        osfamily: 'redhat',
        operatingsystem: 'CentOS'
      }
    end

    let (:params) do
      { cgroups_set: {
        'Apache' => { 'CPUShares' => 600, 'MemoryLimit' => '500M' }
      } }
    end

    it { is_expected.to compile }

    it { should contain_class('cgroups').with(cgroups_set: params[:cgroups_set]) }

    it { should contain_exec('/usr/bin/systemctl set-property Apache.service CPUShares=600') }
    it { should contain_exec('/usr/bin/systemctl set-property Apache.service MemoryLimit=500M') }
  end
end

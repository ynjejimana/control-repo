require 'spec_helper'

describe 'mule_runtime' do

  context 'Redhat context.' do

    # mock facts
    let(:facts) {
      {
        :osfamily => 'Redhat',
      }
    }
 
    # mock params
    let(:params) {
      {
        :mule_ver => '3.8.1',
        :mule_parent_dir => '/opt',
        :user  => 'root',
        :group => 'root',
      }
    }

    it { should compile }
    it { should contain_class('mule_runtime') }
    it { should contain_class('mule_runtime::params') }

    it {
      should contain_file('/opt/mule-standalone-3.8.1').with({
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
      })
    }

    it { 
      should contain_file('/opt/mule').with({
        'ensure' => 'link',
        'owner'  => 'root',
        'group'  => 'root',
      })    
    }

    it { 
      should contain_file('/etc/profile.d/mule.sh').with({
        'ensure' => 'present',
        'mode'   => '0644',
      })    
    }

    it { 
      should contain_file('/etc/init.d/mule').with({
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      })    
    }
  end

  context 'Unsupported OS context.' do
    # mock facts
    let(:facts) {
      {
        :osfamily => 'Windows',
      }
    }

    it { 
      expect { should raise_error(Puppet::Error) } 
    }
  end

end

require 'spec_helper'


describe 'tuned', :type => :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      describe 'with default values for all parameters' do
        it { is_expected.to create_class('tuned') }
        it { is_expected.to compile.with_all_deps }

        case facts[:operatingsystemmajrelease]
        when '6'
          it { is_expected.to contain_file('/etc/tune-profiles/bootcmdline') }
          it { is_expected.to contain_file('/etc/tune-profiles/tuned-main.conf') }
          it { is_expected.to contain_service('ktune').with(
            :enable => true,
            :ensure => 'running',
          )}
        else
          it { is_expected.to contain_file('/etc/tuned/bootcmdline') }
          it { is_expected.to contain_file('/etc/tuned/tuned-main.conf') }
        end

        it { is_expected.to contain_service('tuned').with(
          :enable => true,
          :ensure => 'running',
        )}

        it { is_expected.to contain_package('tuned').with(
          :ensure => 'present'
        )}

        it { is_expected.not_to contain_class('tuned::profile::enable_profile') }
      end

      describe 'with service_ensure => stopped' do
        let(:params) { { :service_ensure => 'stopped' } }
        it { is_expected.to contain_service('tuned').with(
          :enable => true,
          :ensure => params[:service_ensure],
        )}

        case facts[:operatingsystemmajrelease]
        when '6'
          it { is_expected.to contain_service('ktune').with(
            :enable => true,
            :ensure => params[:service_ensure],
          )}
        end
      end

      describe 'with tuned_ensure => absent' do
        let(:params) { { :tuned_ensure => 'absent' } }
        it { is_expected.to contain_package('tuned').with(
          :ensure => params[:tuned_ensure],
        )}
      end

      describe 'with active_profile => virtual-guest' do
        let(:params) { { :active_profile => 'virtual-guest' } }
        it { is_expected.to contain_class('tuned::profile::enable_profile').with(
          :profile_name => params[:active_profile],
        )}

        case facts[:operatingsystemmajrelease]
        when '6'
          it { is_expected.to contain_exec("tuned-adm_enable_profile_#{params[:active_profile]}").with(
            :command => "tuned-adm profile #{params[:active_profile]}",
            :unless  => "grep -q -e '^#{params[:active_profile]}\$' /etc/tune-profiles/active_profile",
          )}
        else
          it { is_expected.to contain_exec("tuned-adm_enable_profile_#{params[:active_profile]}").with(
            :command => "tuned-adm profile #{params[:active_profile]}",
            :unless  => "grep -q -e '^#{params[:active_profile]}\$' /etc/tuned/active_profile",
          )}
        end
      end
    end
  end
end

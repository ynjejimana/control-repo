require 'spec_helper'


describe 'tuned::profile', :type => :define do
  let(:title) { 'mongodb' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:pre_condition) { 'class {"::tuned": active_profile => "mongodb", }' }
      let(:facts) do
        facts
      end

      describe 'create simple profile without scripts' do
        let(:params) {
          {
            :conf_content => 'mycontent'
          }
        }

        case facts[:operatingsystemmajrelease]
        when '6'
          profile_dir = '/etc/tune-profiles/mongodb'
          profile_file = '/etc/tune-profiles/mongodb/tuned.conf'
        else
          profile_dir = '/etc/tuned/mongodb'
          profile_file = '/etc/tuned/mongodb/tuned.conf'
        end

        it { is_expected.to contain_file(profile_dir).with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
        )}

        it { is_expected.to contain_file(profile_file).with(
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          'content' => params[:conf_content],
        )}

        it { is_expected.not_to contain_define('tuned::profile::create_script') }
      end

      describe 'create profile with scripts' do
        let(:params) {
          {
            :scripts => {
              'script1.sh' => "content1",
              'script2.sh' => "content2",
            }
          }
        }

        case facts[:operatingsystemmajrelease]
        when '6'
          profile_dir = '/etc/tune-profiles/mongodb'
        else
          profile_dir = '/etc/tuned/mongodb'
        end

        it { is_expected.to contain_file("#{profile_dir}/script1.sh").with(
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'content' => 'content1',
        )}

        it { is_expected.to contain_file("#{profile_dir}/script2.sh").with(
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'content' => 'content2',
        )}
      end
    end
  end
end

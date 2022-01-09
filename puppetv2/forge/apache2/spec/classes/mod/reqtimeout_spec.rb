require 'spec_helper'

describe 'apache2::mod::reqtimeout', :type => :class do
  it_behaves_like "a mod class, without including apache"
  context "on a Debian OS" do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
        :operatingsystem        => 'Debian',
        :id                     => 'root',
        :kernel                 => 'Linux',
        :path                   => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        :lsbdistcodename        => 'squeeze',
        :is_pe                  => false,
      }
    end
    context "passing no parameters" do
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-40,minrate=500\nRequestReadTimeout body=10,minrate=500$/) }
    end
    context "passing timeouts => ['header=20-60,minrate=600', 'body=60,minrate=600']" do
      let :params do
        {:timeouts => ['header=20-60,minrate=600', 'body=60,minrate=600']}
      end
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-60,minrate=600\nRequestReadTimeout body=60,minrate=600$/) }
    end
    context "passing timeouts => 'header=20-60,minrate=600'" do
      let :params do
        {:timeouts => 'header=20-60,minrate=600'}
      end
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-60,minrate=600$/) }
    end
  end
  context "on a RedHat OS" do
    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
        :operatingsystem        => 'Redhat',
        :id                     => 'root',
        :kernel                 => 'Linux',
        :path                   => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        :is_pe                  => false,
      }
    end
    context "passing no parameters" do
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-40,minrate=500\nRequestReadTimeout body=10,minrate=500$/) }
    end
    context "passing timeouts => ['header=20-60,minrate=600', 'body=60,minrate=600']" do
      let :params do
        {:timeouts => ['header=20-60,minrate=600', 'body=60,minrate=600']}
      end
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-60,minrate=600\nRequestReadTimeout body=60,minrate=600$/) }
    end
    context "passing timeouts => 'header=20-60,minrate=600'" do
      let :params do
        {:timeouts => 'header=20-60,minrate=600'}
      end
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-60,minrate=600$/) }
    end
  end
  context "on a FreeBSD OS" do
    let :facts do
      {
        :osfamily               => 'FreeBSD',
        :operatingsystemrelease => '9',
        :concat_basedir         => '/dne',
        :operatingsystem        => 'FreeBSD',
        :id                     => 'root',
        :kernel                 => 'FreeBSD',
        :path                   => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        :is_pe                  => false,
      }
    end
    context "passing no parameters" do
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-40,minrate=500\nRequestReadTimeout body=10,minrate=500$/) }
    end
    context "passing timeouts => ['header=20-60,minrate=600', 'body=60,minrate=600']" do
      let :params do
        {:timeouts => ['header=20-60,minrate=600', 'body=60,minrate=600']}
      end
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-60,minrate=600\nRequestReadTimeout body=60,minrate=600$/) }
    end
    context "passing timeouts => 'header=20-60,minrate=600'" do
      let :params do
        {:timeouts => 'header=20-60,minrate=600'}
      end
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-60,minrate=600$/) }
    end
  end
  context "on a Gentoo OS" do
    let :facts do
      {
        :osfamily               => 'Gentoo',
        :operatingsystem        => 'Gentoo',
        :operatingsystemrelease => '3.16.1-gentoo',
        :concat_basedir         => '/dne',
        :id                     => 'root',
        :kernel                 => 'Linux',
        :path                   => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/bin',
        :is_pe                  => false,
      }
    end
    context "passing no parameters" do
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-40,minrate=500\nRequestReadTimeout body=10,minrate=500$/) }
    end
    context "passing timeouts => ['header=20-60,minrate=600', 'body=60,minrate=600']" do
      let :params do
        {:timeouts => ['header=20-60,minrate=600', 'body=60,minrate=600']}
      end
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-60,minrate=600\nRequestReadTimeout body=60,minrate=600$/) }
    end
    context "passing timeouts => 'header=20-60,minrate=600'" do
      let :params do
        {:timeouts => 'header=20-60,minrate=600'}
      end
      it { is_expected.to contain_class("apache2::params") }
      it { is_expected.to contain_apache__mod('reqtimeout') }
      it { is_expected.to contain_file('reqtimeout.conf').with_content(/^RequestReadTimeout header=20-60,minrate=600$/) }
    end
  end
end

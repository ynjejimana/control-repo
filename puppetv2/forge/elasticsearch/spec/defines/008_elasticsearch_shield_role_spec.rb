require 'spec_helper'

describe 'elasticsearch::shield::role' do

  let(:title) { 'elastic_role' }

  context 'with an invalid role name' do
    context 'too long' do
      let(:title) { 'A'*31 }
      it { should raise_error(Puppet::Error, /expected length/i) }
    end
  end

  context 'with default parameters' do

    let(:params) do
      {
        :privileges => {
          'cluster' => '*'
        },
        :mappings => [
          "cn=users,dc=example,dc=com",
          "cn=admins,dc=example,dc=com",
          "cn=John Doe,cn=other users,dc=example,dc=com"
        ]
      }
    end

    it { should contain_elasticsearch__shield__role('elastic_role') }
    it { should contain_elasticsearch_shield_role('elastic_role') }
    it do
      should contain_elasticsearch_shield_role_mapping('elastic_role').with(
        'ensure' => 'present',
        'mappings' => [
          "cn=users,dc=example,dc=com",
          "cn=admins,dc=example,dc=com",
          "cn=John Doe,cn=other users,dc=example,dc=com"
        ]
      )
    end
  end
end

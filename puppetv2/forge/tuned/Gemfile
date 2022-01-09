source ENV['GEM_SOURCE'] || "https://rubygems.org"

ENV['PUPPET_GEM_VERSION'].nil? ? puppetversion = '~> 3.0' : puppetversion = ENV['PUPPET_GEM_VERSION'].to_s
gem 'puppet', puppetversion, :require => false
gem 'facter', "~> 2.4.0",    :require => false

group :development, :unit_tests do
  gem 'rspec-puppet',                                              :require => false
  gem 'parallel_tests', "~> 2.9.0",                                :require => false
  gem 'rspec-puppet-facts',                                        :require => false
  gem 'puppetlabs_spec_helper',                                    :require => false
  gem 'puppet-lint',                                               :require => false
  gem 'puppet-syntax',                                             :require => false
  gem 'metadata-json-lint', "~> 1.1.0",                            :require => false
  gem 'puppet-blacksmith',                                         :require => false
  gem 'mime-types', "~> 2.99",                                     :require => false if RUBY_VERSION < '2.0.0'
  gem 'rspec-puppet-utils',                                        :require => false
  gem 'puppet-lint-absolute_classname-check',                      :require => false
  gem 'puppet-lint-empty_string-check',                            :require => false
  gem 'puppet-lint-file_ensure-check',                             :require => false
  gem 'puppet-lint-leading_zero-check',                            :require => false
  gem 'puppet-lint-spaceship_operator_without_tag-check',          :require => false
  gem 'puppet-lint-trailing_comma-check',                          :require => false
  gem 'puppet-lint-undef_in_function-check',                       :require => false
  gem 'puppet-lint-unquoted_string-check',                         :require => false
  gem 'puppet-lint-version_comparison-check',                      :require => false
  gem 'puppet-lint-variable_contains_upcase',                      :require => false
  gem 'puppet-lint-alias-check',                                   :require => false
  gem 'puppet-lint-classes_and_types_beginning_with_digits-check', :require => false
  gem 'puppet-lint-file_source_rights-check',                      :require => false
  gem 'tins', '1.6.0',                                             :require => false
  gem 'term-ansicolor', "1.3.2",                                   :require => false if RUBY_VERSION < '2.0.0'
  gem 'coveralls',                                                 :require => false
  gem 'simplecov-console',                                         :require => false
  gem 'rubocop', '~> 0.49.1',                                      :require => false if RUBY_VERSION >= '2.3.0'
  gem 'rubocop-rspec', '~> 1.15.0',                                :require => false if RUBY_VERSION >= '2.3.0'
end

group :system_tests do
  gem 'beaker-rspec',                 :require => false
  gem 'serverspec',                   :require => false
  gem 'vagrant-wrapper',              :require => false
  gem 'beaker-puppet_install_helper', :require => false
end

group :development do
  gem 'guard-rake', :require => false
end

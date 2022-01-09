Puppet::Type.type(:splunkforwarder_transforms).provide(
  :ini_setting,
  # set ini_setting as the parent provider
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  def self.prefetch(resources)
    catalog = resources[resources.keys.first].catalog
    splunk_config = catalog.resources.find{|s| s.type == :splunk_config}
    confdir = splunk_config['forwarder_confdir'] || raise(Puppet::Error, 'Unknown splunk forwarder confdir')
    @file_path = File.join(confdir, 'transforms.conf')
  end

  def self.file_path
    @file_path
  end
end

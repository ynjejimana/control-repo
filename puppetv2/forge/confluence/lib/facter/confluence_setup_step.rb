# Written by Jarrod Moore (jmoore@harbourmsp.com)
# Version: 1.0
# Last Updated: 17/04/2013

require 'facter'
require 'rexml/document'

# Change this if the name of the init script ever changes
init_script = "/etc/init.d/confluence"
# Value of fact if install status cannot be found
setupstep = nil

# This pulls out the value from an ini file for a given parameter
# Expects line to be structured as "<something> = <something>"
def find_config_parameter(filename, parameter)
	values = Hash[File.read(filename).scan(/(\S*)\s*=\s*(\S*)\s*\n/)]
	values[parameter]
end

# This function pulls out the setupStep tag from the confluence config XML
def setup_step_from_xml(filename)
	xmldoc = REXML::Document.new(File.open(filename))
	REXML::XPath.each(xmldoc, '*/setupStep/text()') do |step|
		step
	end
end

# This is where the actual value is pulled out
begin
	installdir = find_config_parameter(init_script, "CATALINA_HOME")
	homedir = find_config_parameter(installdir + "/confluence/WEB-INF/classes/confluence-init.properties", "confluence.home")
	setupstep = setup_step_from_xml(homedir + "/confluence.cfg.xml").to_s
rescue
end

# This block adds the fact to facter
Facter.add("confluence_setup_step") do
	setcode do
		setupstep
	end
end

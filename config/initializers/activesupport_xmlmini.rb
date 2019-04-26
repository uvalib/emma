# config/initializers/activesupport_xmlmini.rb

require 'active_support/xml_mini'

module ActiveSupport
  XmlMini.backend = 'Nokogiri'
end

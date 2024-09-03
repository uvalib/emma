# app/views/about/index.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Main About page as XML.

tables = {
  links:  project_links(format: :xml),
  refs:   project_refs(format: :xml),
}

xml.instruct!
xml.about do
  xml.timestamp DateTime.now
  tables.each_pair do |section, values|
    xml.tag!(section) do
      values.each_pair do |name, value|
        xml.tag! name, value
      end
    end
  end
end

# app/views/data/_details.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as XML.

list ||= nil
list   = list.is_a?(Array) ? list.dup : Array.wrap(list)

schema_key, column_types = (list.shift || { schema: {} }).first

xml_opt = { dasherize: false, skip_instruct: true, skip_types: true }

xml.count list.size
column_types.to_xml(root: schema_key, builder: xml, **xml_opt)
list.to_xml(root: :records, builder: xml, **xml_opt)

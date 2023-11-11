# app/views/data/_details.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as XML.

item ||= nil
item   = item.is_a?(Array) ? item.dup : Array.wrap(item)

schema_key, column_types = (item.shift || { schema: {} }).first

xml_opt = { dasherize: false, skip_instruct: true, skip_types: true }

xml.count item.size
column_types.to_xml(root: schema_key, builder: xml, **xml_opt)
item.to_xml(root: :records, builder: xml, **xml_opt)

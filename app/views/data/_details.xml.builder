# app/views/data/_details.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as XML.

records ||= nil

records = records&.dup || []
schema_key, column_types = (records.shift || { schema: {} }).first

xml_opt = { dasherize: false, skip_instruct: true, skip_types: true }

xml.count records.size
column_types.to_xml(root: schema_key, builder: xml, **xml_opt)
records.to_xml(root: :records, builder: xml, **xml_opt)

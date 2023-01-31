# app/views/manifest/show.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a manifest as XML.

item ||= @item

xml.instruct!
xml.manifests do
  xml.timestamp DateTime.now
  xml << render('manifest/details', manifest: item)
end

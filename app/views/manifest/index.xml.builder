# app/views/manifest/index.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA manifests as XML.

list ||= paginator.page_items

xml.instruct!
xml.manifests do
  xml.timestamp DateTime.now
  xml.count     list.size
  list.each do |item|
    xml << render('manifest/details', manifest: item)
  end
end

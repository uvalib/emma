# app/views/manifest/index.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA manifests as XML.

list ||= @list || {}

xml.instruct!
xml.manifests do
  # noinspection RubyMismatchedArgumentType
  xml.timestamp DateTime.now
  xml.count     list.size
  list.each do |manifest|
    xml << render('manifest/details', manifest: manifest)
  end
end

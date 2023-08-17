# config/initializers/mime_types.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Add new mime types for use in respond_to blocks:

Mime::Type.register 'application/x-rar-compressed', :rar
Mime::Type.register 'application/x-zip-compressed', :zip
Mime::Type.register 'application/xml-dtd',          :dtd
Mime::Type.register 'application/zip',              :zip, %w[application/x-zip]
Mime::Type.register 'text/xml',                     :xsd

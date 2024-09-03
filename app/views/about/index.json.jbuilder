# app/views/about/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Main About page.

tables = {
  links:  project_links(format: :json),
  refs:   project_refs(format: :json),
}

json.timestamp DateTime.now

json.set! :about do
  tables.each_pair do |section, values|
    json.set!(section) do
      values.each_pair do |name, value|
        json.set! name, value
      end
    end
  end
end

# test/test_helper/system_tests/ingest.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for working directly with the Unified Index.
#
module TestHelper::SystemTests::Ingest

  include TestHelper::SystemTests::Common

  include IngestConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Cause the identified items to be updated in the Unified Index.
  #
  # @param [Array<Upload,String>] entries
  #
  # @return [Boolean]
  #
  def reindex(*entries)
    list = Upload.get_relation(*entries).to_a
    result = ingest_api.put_records(*list)
    result.exec_report.error_messages.each { |e| $stderr.puts e }.blank?
  end

end

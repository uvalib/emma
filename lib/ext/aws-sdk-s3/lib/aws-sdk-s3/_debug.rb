# lib/ext/aws-sdk-s3/lib/aws-sdk-s3/_debug.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for aws-sdk-s3 gem extensions.

__loading_begin(__FILE__)

require 'aws-sdk-s3'

module Aws::S3

  module ExtensionDebugging

    if DEBUG_AWS
      include Emma::Extension::Debugging
    else
      include Emma::Extension::NoDebugging
    end

    # =========================================================================
    # :section: Emma::Extension::Debugging overrides
    # =========================================================================

    public

    def __ext_log_leader
      super('AWS')
    end

    def __ext_log_tag
      case self
        when Aws::S3::Client                  then 'CLI >'
        when Aws::S3::Bucket                  then 'Bkt  '
        when Aws::S3::Object                  then 'Obj  '
        when Aws::S3::MultipartStreamUploader then 'MSU -'
        else                                       '%-63s' % __ext_class
      end
    end

  end

end

__loading_end(__FILE__)

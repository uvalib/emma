# app/services/ingest_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api_service/error'

class IngestService::Error            < ApiService::Error;            end
class IngestService::ResponseError    < ApiService::ResponseError;    end
class IngestService::EmptyResultError < ApiService::EmptyResultError; end
class IngestService::HtmlResultError  < ApiService::HtmlResultError;  end
class IngestService::RedirectionError < ApiService::RedirectionError; end

__loading_end(__FILE__)

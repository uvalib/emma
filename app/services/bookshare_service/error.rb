# app/services/bookshare_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api_service/error'

class BookshareService::Error            < ApiService::Error;            end
class BookshareService::ResponseError    < ApiService::ResponseError;    end
class BookshareService::EmptyResultError < ApiService::EmptyResultError; end
class BookshareService::HtmlResultError  < ApiService::HtmlResultError;  end
class BookshareService::RedirectionError < ApiService::RedirectionError; end

__loading_end(__FILE__)

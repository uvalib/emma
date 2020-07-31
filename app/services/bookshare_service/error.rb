# app/services/bookshare_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class BookshareService::Error            < ApiService::Error;            end
class BookshareService::NoInputError     < ApiService::NoInputError;     end
class BookshareService::EmptyResultError < ApiService::EmptyResultError; end
class BookshareService::HtmlResultError  < ApiService::HtmlResultError;  end
class BookshareService::RedirectionError < ApiService::RedirectionError; end

__loading_end(__FILE__)

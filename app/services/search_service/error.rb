# app/services/search_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SearchService::Error            < ApiService::Error;            end
class SearchService::ResponseError    < ApiService::ResponseError;    end
class SearchService::EmptyResultError < ApiService::EmptyResultError; end
class SearchService::HtmlResultError  < ApiService::HtmlResultError;  end
class SearchService::RedirectionError < ApiService::RedirectionError; end

__loading_end(__FILE__)

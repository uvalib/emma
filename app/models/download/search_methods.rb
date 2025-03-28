# app/models/download/search_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Class methods for accessing Download records.
#
module Download::SearchMethods

  include Record::Searchable

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  NO_PUBLISHER = '(NONE)'

  # Make sure that #sql_clause does not turn publisher names containing commas
  # into a list of items.
  #
  # @param [Array<String,Array,Hash>] terms
  # @param [Hash,String,Boolean,nil]  sort  No sort if *nil*, *false* or blank.
  # @param [Hash]                     opt   Passed to #where except:
  #
  # @option opt [Integer, nil]      :offset
  # @option opt [Integer, nil]      :limit
  # @option opt [String, Date]      :start_date   Earliest :updated_at.
  # @option opt [String, Date]      :end_date     Latest :updated_at.
  # @option opt [String, Date]      :after        All :updated_at after this.
  # @option opt [String, Date]      :before       All :updated_at before this.
  # @option opt [String,Symbol,nil] :meth         Caller for diagnostics.
  #
  # @return [ActiveRecord::Relation]
  #
  def make_relation(*terms, sort: nil, **opt)
    if (pub = opt[:publisher]).present?
      if (pub == '-') || (pub == NO_PUBLISHER)
        opt[:publisher] = 'nil'
      elsif pub.include?(',')
        opt[:publisher] = quote(pub)
      end
    end
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)

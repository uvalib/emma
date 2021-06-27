# app/records/bs/shared/link_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements with links.
#
module Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the indicated link if present.
  #
  # If *rel_name* is an array, the first matching *href* will be returned.
  #
  # @param [String, Symbol, Array] rel_name
  #
  # @return [String]
  # @return [nil]                     If *rel_name* is not valid or present.
  #
  def get_link(rel_name)
    # noinspection RailsParamDefResolve
    array = Array.wrap(try(:links)).compact.presence or return
    keys  = Array.wrap(rel_name).map(&:to_s).uniq
    array.find { |link| break link.href.presence if keys.include?(link.rel) }
  end

  # Return the links present in the record.
  #
  # @param [Hash] opt
  #
  # @option opt [Symbol,String,Array] :only     Limit to these rel name(s).
  # @option opt [Symbol,String,Array] :except   Exclude these rel name(s).
  # @option opt [Boolean]             :self     Unless this is *true*, 'self'
  #                                               links will be excluded.
  #
  # @return [Array<String>]
  # @return [nil]                     If links are not valid or present.
  #
  def record_links(**opt)
    # noinspection RailsParamDefResolve
    array  = Array.wrap(try(:links)).compact.presence or return
    only   = Array.wrap(opt[:only]).compact.map(&:to_s).uniq.presence
    except = Array.wrap(opt[:except]).compact.map(&:to_s)
    except << 'self' unless opt[:self]
    except = except.uniq.presence
    array.map { |link|
      next if only && !only.include?(link.rel)
      next if except&.include?(link.rel)
      link.href.presence
    }.compact
  end

end

__loading_end(__FILE__)

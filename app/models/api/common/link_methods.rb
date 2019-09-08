# app/models/api/common/link_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements with links.
#
module Api::Common::LinkMethods

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
    return if !respond_to?(:links) || (array = Array.wrap(links)).blank?
    keys = Array.wrap(rel_name).map(&:to_s).uniq
    array.find do |link|
      break link.href.presence if keys.include?(link.rel)
    end
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
    return if !respond_to?(:links) || (array = Array.wrap(links)).blank?
    keys = Array.wrap(opt[:only]).map(&:to_s).uniq.presence
    except =
      Array.wrap(opt[:except]).map(&:to_s).tap { |a|
        a << 'self' unless opt[:self]
      }.uniq.presence
    array.map { |link|
      next if keys && !keys.include?(link.rel)
      next if except&.include?(link.rel)
      link.href.presence
    }.compact
  end

end

__loading_end(__FILE__)

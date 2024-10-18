# app/models/org/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Org::Assignable

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::Assignable
  end
  # :nocov:

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Ensure that blanks are allowed, that input values are normalized, and that
  # :status_date is set if :status is updated.
  #
  # @param [Model, Hash, ActionController::Parameters, nil] attr
  # @param [Hash]                                           opt
  #
  # @return [Hash]
  #
  def normalize_attributes(attr, **opt)
    opt.reverse_merge!(key_norm: true, compact: false)
    super.tap do |result|
      if result[:status]
        result[:status_date] ||= (result[:updated_at] ||= DateTime.now)
      end
      result[:contact]&.map! { _1.is_a?(User) ? _1.id : _1 }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Turn a :long_name value into a :short_name value.
  #
  # @param [String] name
  #
  # @return [String]
  #
  def abbreviate_org(name)
    words = name.split(/[^[:alnum:]]+/).reject! { _1.start_with?(/\d/) }
    nouns = words.reject { %w[a an the of].include?(_1.downcase) }
    (nouns.presence || words).map(&:first).join
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)

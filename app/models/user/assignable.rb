# app/models/user/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module User::Assignable

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::Assignable
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Parameter keys related to password management.
  #
  # @type [Array<Symbol>]
  #
  PASSWORD_KEYS = %i[password password_confirmation].freeze

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Ensure that :status_date is set if :status is updated.
  #
  # @param [Model, Hash, ActionController::Parameters, nil] attr
  # @param [Hash]                                           opt
  #
  # @return [Hash]
  #
  def normalize_attributes(attr, **opt)
    super.tap do |result|
      if result[:status]
        result[:status_date] ||= (result[:updated_at] ||= DateTime.now)
      end
    end
  end

  # Ensure that :password and :password_confirmation are allowed.
  #
  # @return [Array<Symbol>]
  #
  def allowed_keys
    super + PASSWORD_KEYS
  end

  # Allow passing #PASSWORD_KEYS to #normalize_attributes.
  #
  # @param [Symbol]   k
  # @param [any, nil] v
  #
  # @return [String]                  The reason why *k* will be rejected.
  # @return [nil]                     If *k* is acceptable.
  #
  def invalid_field(k, v)
    super unless PASSWORD_KEYS.include?(k)
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

# app/models/user/identification.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module User::Identification

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Emma::Common
    include Record::Identification
  end
  # :nocov:

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Value of :id for the indicated record.
  #
  # @param [any, nil] item            User, String, Integer; default: `self`
  # @param [Hash]     opt
  #
  # @return [String]
  # @return [nil]                     If no matching record was found.
  #
  def id_value(item, **opt)
    super || super(self_class.instance_for(item), **opt)
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  def user_column = id_column

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Return with the specified User record or *nil* if one could not be found.
  #
  # @param [any, nil] item            String, Symbol, Integer, Hash, Model
  # @param [Hash]     opt
  #
  # @option opt [Boolean] :fatal      False by default.
  #
  # @return [User, nil]               A fresh record unless *item* is a User.
  #
  def find_record(item, **opt)
    item = item.to_s if item.is_a?(Symbol)
    opt.reverse_merge!(fatal: false)
    super || super(self_class.instance_for(item), **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)

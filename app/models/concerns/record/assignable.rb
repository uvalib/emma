# app/models/record/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods relating to record field assignment.
#
module Record::Assignable

  extend ActiveSupport::Concern

  include Record
  include Record::Identification

  include SqlMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveRecord::Core
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Option parameters for #attribute_options:
  #
  # * :from     A record used to provide initial field values.
  # * :user     Transformed into a :user_id value.
  # * :force    Allow these fields unconditionally.
  # * :except   Ignore these fields (default: []).
  # * :only     Not limited if *false* (default: `#field_name`).
  # * :blanks   If *true*, allow blanks (default: *false*).
  # * :options  An Options instance.
  #
  ATTRIBUTE_OPTIONS_OPTS = %i[from user force except only blanks options]

  # Called to prepare values to be used for assignment to record attributes.
  #
  # @param [Hash, ActionController::Parameters, Model, nil] attr
  # @param [Hash, nil]                                      opt
  #
  # @option attr [ApplicationRecord]            :from
  # @option attr [User, String, Integer]        :user
  # @option attr [Symbol, Array<Symbol>]        :force
  # @option attr [Symbol, Array<Symbol>]        :except
  # @option attr [Symbol, Array<Symbol>, false] :only
  # @option attr [Boolean]                      :blanks
  #
  # @raise [RuntimeError]             If the type of *attr* is invalid.
  #
  # @return [Hash{Symbol=>Any}]
  #
  # @see #ATTRIBUTE_OPTIONS_OPTS
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def attribute_options(attr, opt = nil)
    return {} if attr.blank?
    attr = attr.params      if attr.respond_to?(:params)
    attr = attr.to_unsafe_h if attr.respond_to?(:to_unsafe_h)
    if attr.is_a?(ApplicationRecord)
      unless attr.is_a?(record_class)
        Log.warn { "#{record_class}: assigning from a #{attr.class} record" }
      end
      attr = attr.fields.except!(*ignored_keys)
    elsif attr.is_a?(Hash)
      attr = attr.symbolize_keys
    else
      raise "#{attr.class}: unexpected"
    end
    attr.merge!(opt) if opt.present?

    opt   = extract_hash!(attr, *ATTRIBUTE_OPTIONS_OPTS)
    from  = opt[:from] && attribute_options(opt[:from], except: ignored_keys)
    user  = (opt[:user] unless attr.key?(:user_id) || from&.dig(:user_id))
    opts  = [opt.delete(:options), from&.delete(:options)].compact.first
    force = Array.wrap(opt[:force])
    excp  = Array.wrap(opt[:except])
    only  = !false?(opt[:only]) && Array.wrap(opt[:only] || allowed_keys)

    attr.reverse_merge!(from)     if from.present?
    attr.merge!(user_id: user)    if (user &&= User.id_value(user))
    attr.slice!(*(only + force))  if only.present?
    attr.except!(*(excp - force)) if excp.present?
    attr.merge!(options: opts)    if opts

    # noinspection RubyMismatchedReturnType
    opt[:blanks] ? attr : reject_blanks(attr)
  end

  # The fields that will be accepted by #attribute_options.
  #
  # @return [Array<Symbol>]
  #
  def allowed_keys
    field_names - [id_column]
  end

  # The fields that will be ignored by #attribute_options from a source
  # passed in via the :from parameter.
  #
  # @return [Array<Symbol>]
  #
  def ignored_keys
    [id_column, :created_at, :updated_at]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods
    include Record::Assignable
  end

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  module InstanceMethods

    include Record::Assignable

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::AttributeAssignment
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Model/controller options passed in through the constructor.
    #
    # @return [Entry::Options]
    #
    attr_reader :model_options

    # set_model_options
    #
    # @param [Entry::Options, Hash, nil] options
    #
    # @return [Entry::Options, nil]
    #
    def set_model_options(options)
      options = options[:options]  if options.is_a?(Hash)
      # noinspection RubyMismatchedReturnType
      @model_options = (options.dup if options.is_a?(Options))
    end

    # =========================================================================
    # :section: ActiveRecord overrides
    # =========================================================================

    public

    # Update database fields, including the structured contents of JSON fields.
    #
    # @param [Hash, ActionController::Parameters, Model, nil] attr
    # @param [Hash, nil]                                      opt
    #
    # @return [void]
    #
    # @see #attribute_options
    # @see ActiveModel::AttributeAssignment#assign_attributes
    #
    def assign_attributes(attr, opt = nil)
      attr = attribute_options(attr, opt)
      set_model_options(attr&.delete(:options))
      super(attr)
    rescue => err # TODO: testing - remove?
      Log.warn { "#{record_name}.#{__method__}: #{err.class}: #{err.message}" }
      raise err
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include InstanceMethods

  end

end

__loading_end(__FILE__)

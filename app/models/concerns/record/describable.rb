# app/models/concerns/record/describable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Textual record descriptions.
#
module Record::Describable

  extend ActiveSupport::Concern

  include Record
  include Record::EmmaIdentification

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract the interpolation methods defined in the current context indexed by
  # their respective interpolation keys.
  #
  # E.g.: The method #describe_repo is added as { repo: :describe_repo }.
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  def interpolation_table
    @interpolation_table ||= generate_interpolation_table
  end

  # Replace #sprintf named references with the matching values extracted from
  # *model* or *opt*.
  #
  # If the name is capitalized or all uppercase (e.g. "%{Name}" or "%{NAME}")
  # then the interpolated value will follow the same case.
  #
  # @param [String, Any] text
  # @param [Model, Any]  model
  # @param [Hash]        opt
  #
  # @return [String]                  A (possibly modified) copy of *text*.
  #
  # @see Kernel#sprintf
  #
  def interpolations(text, model, **opt)
    text  = text.to_s unless text.is_a?(String)
    terms =
      named_references_and_formats(text, default_fmt: nil).map { |term, format|
        term = term.to_s
        key  = term.underscore.to_sym
        next unless (meth = interpolation_table[key])
        value = send(meth, model, **opt)
        case term
          when term.capitalize
            key   = key.capitalize
            value = (value || term).capitalize
          when term.upcase
            key   = key.upcase
            value = (value || term).upcase
          else
            value ||= term.upcase
        end
        value %= format if format
        [key, value]
      }.compact.to_h.presence
    terms ? (text % terms) : text
  end

  # Process a lambda or method reference and return a final result string.
  #
  # @param [String, Symbol, Proc, nil] note
  # @param [Model, Any]                model
  # @param [Hash]                      opt
  #
  # @option opt [String, Symbol, Proc] :note  Only used if *note* is *nil*.
  #
  # @return [String]                  From #interpolations.
  # @return [nil]                     If *note* is *nil*.
  #
  # @see Kernel#sprintf
  #
  def process_note(note = nil, model, **opt)
    opt_note = opt.delete(:note)
    case (note ||= opt_note)
      when nil    then return
      when String then # Use *note* as-is.
      when Symbol then note = model.send(note, **opt)
      when Proc   then note = note.call(model, **opt)
      else             raise "#{__method__}: #{note.class} unexpected"
    end
    # noinspection RubyMismatchedArgumentType
    interpolations(note, model, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Extract the interpolation methods defined in the current context indexed by
  # their respective interpolation keys.
  #
  # E.g.: The method #describe_repo is added as { repo: :describe_repo }.
  #
  # @param [Class, Module, Any] mod   Default self or self.class.
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  # @see InterpolationMethods
  #
  def generate_interpolation_table(mod = nil)
    mod ||= self.is_a?(Module) ? self : self.class
    mod = mod.ancestors.find { |m| m.name&.include?('InterpolationMethods') }
    mod.methods.map { |meth|
      (term = meth.to_s.delete_prefix!('describe_')) and [term.to_sym, meth]
    }.compact.to_h.tap { |result|
      if result[:submission] && !result[:sid]
        result[:sid] = result[:submission]
      end
    }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Common interpolation methods.
  #
  # @see #generate_interpolation_table
  #
  # == Implementation Notes
  # These are encapsulated in their own module to support extendability.
  #
  module InterpolationMethods

    include Record::Describable

    extend self

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A replacement value for '%{id}' in #sprintf formats.
    #
    # @param [Model, Any] model
    # @param [Hash]       opt
    #
    # @return [String, nil]
    #
    # @see Record::Identification#id_value
    #
    def describe_id(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      id_value(model, **opt)
    end

    # A replacement value for '%{repo}' or '%{repository}' in #sprintf formats.
    #
    # @param [Model, Any] model
    # @param [Hash]       opt
    #
    # @return [String, nil]
    #
    # @see Record::EmmaIdentification#repository_name
    #
    def describe_repo(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      repo = repository_value(model)
      repository_name(repo || opt)
    end

    # A replacement value for '%{sid}' in #sprintf formats.
    #
    # @param [Model, Any] model
    # @param [Hash]       opt
    #
    # @return [String, nil]
    #
    # @see Record::EmmaIdentification#sid_value
    #
    def describe_sid(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      sid_value(model, **opt)
    end

    # A replacement value for '%{submission}' in #sprintf formats.
    #
    # @param [Model, Any] model
    # @param [Hash]       opt
    #
    # @return [String, nil]
    #
    # @see Record::EmmaIdentification#sid_value
    #
    def describe_submission(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      sid = describe_sid(model, **opt)
      "submission #{sid.inspect}" # TODO: I18n
    end

    # A replacement value for '%{user}' in #sprintf formats.
    #
    # @param [Model, Any, nil] model
    # @param [Hash]            _opt   Unused.
    #
    # @return [String, nil]
    #
    # @see User#uid_value
    #
    def describe_user(model = nil, **_opt)
      model ||= self_for_instance_method(__method__)
      # noinspection RailsParamDefResolve
      user = model.try(:user) and User.uid_value(user)
    end

    # A replacement value for '%{user_id}' in #sprintf formats.
    #
    # @param [Model, Any, nil] model
    # @param [Hash]            _opt   Unused.
    #
    # @return [String, nil]
    #
    # @see User#id_value
    #
    def describe_user_id(model = nil, **_opt)
      model ||= self_for_instance_method(__method__)
      # noinspection RailsParamDefResolve
      user = model.try(:user) and User.id_value(user)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A textual description of the type of the Model instance for use as a
    # replacement value for '%{text}' in #sprintf formats.
    #
    # @param [Model, Any] model
    # @param [Hash]       opt
    #
    # @return [String]
    #
    # == Usage Notes
    # The including class is expected to define an overriding class method.
    #
    def describe_type(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      model.class.send(__method__, model, **opt)
    end

    # A textual description of the status of the Model instance.
    #
    # @param [Model, Any] model
    # @param [Hash]       opt
    #
    # @return [String]
    #
    # == Usage Notes
    # The including class is expected to define an overriding class method.
    #
    def describe_status(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      model.class.send(__method__, model, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # self_for_instance_method
    #
    # @param [Symbol] meth            Calling method.
    #
    # @raise [RuntimeError]           If a class method is being defined.
    #
    # @return [self]                  If an instance method is being defined.
    #
    def self_for_instance_method(meth)
      return self unless self.is_a?(Class)
      raise "#{meth}: *model* param required for class method"
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods

    include Record::Describable
    include Record::Describable::InterpolationMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Creates an override to InterpolationMethods which includes all of its
    # methods along with the methods defined within the block.
    #
    # @return [void]
    #
    def interpolation_methods(&block)
      new_module =
        module_eval <<~HEREDOC
          module InterpolationMethods
            include Record::Describable::InterpolationMethods
            extend self
          end
        HEREDOC
      new_module.module_exec(&block)
      include new_module
      extend  new_module
    end

  end

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  module InstanceMethods

    include Record::Describable
    include Record::Describable::InterpolationMethods

    # =========================================================================
    # :section: Record::Describable overrides
    # =========================================================================

    public

    # @see Record::Describable#interpolation_table
    def interpolation_table
      self.class.send(__method__)
    end

    # @see Record::Describable#interpolations
    def interpolations(text, model = nil, **opt)
      super(text, (model || self), **opt)
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

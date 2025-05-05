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
  # @note Currently used only by #interpolations.
  # :nocov:
  def interpolation_table
    @interpolation_table ||= generate_interpolation_table
  end
  # :nocov:

  # Replace #sprintf named references with the matching values extracted from
  # *model* or *opt*.
  #
  # If the name is capitalized or all uppercase (e.g. "%{Name}" or "%{NAME}")
  # then the interpolated value will follow the same case.
  #
  # @param [any, nil] text
  # @param [any, nil] model           Model
  # @param [Hash]     opt
  #
  # @return [String]                  A (possibly modified) copy of *text*.
  #
  # @see Kernel#sprintf
  #
  # @note Currently used only by #process_note.
  # :nocov:
  def interpolations(text, model, **opt)
    text  = text.to_s unless text.is_a?(String)
    terms =
      named_references_and_formats(text).map { |term, format|
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
  # :nocov:

  # Process a lambda or method reference and return a final result string.
  #
  # @param [String, Symbol, Proc, nil] note
  # @param [any, nil]                  model  Model
  # @param [Hash]                      opt
  #
  # @option opt [String, Symbol, Proc] :note  Only used if *note* is *nil*.
  #
  # @return [String]                  From #interpolations.
  # @return [nil]                     If *note* is *nil*.
  #
  # @see Kernel#sprintf
  #
  # @note Currently unused.
  # :nocov:
  def process_note(note = nil, model, **opt)
    opt_note = opt.delete(:note)
    case (note ||= opt_note)
      when nil    then return
      when String then # Use *note* as-is.
      when Symbol then note = model.send(note, **opt)
      when Proc   then note = note.call(model, **opt)
      else             raise "#{__method__}: #{note.class} unexpected"
    end
    interpolations(note, model, **opt)
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Extract the interpolation methods defined in the current context indexed by
  # their respective interpolation keys.
  #
  # E.g.: The method #describe_repo is added as { repo: :describe_repo }.
  #
  # @param [any, nil] mod             Default self or self.class.
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  # @see InterpolationMethods
  #
  # @note Currently used only by #interpolation_table.
  # :nocov:
  def generate_interpolation_table(mod = nil)
    mod ||= self.is_a?(Module) ? self : self.class
    mod = mod.ancestors.find { _1.name&.include?('InterpolationMethods') }
    mod.methods.map { |meth|
      (term = meth.to_s.delete_prefix!('describe_')) and [term.to_sym, meth]
    }.compact.to_h.tap { |result|
      if result[:submission] && !result[:sid]
        result[:sid] = result[:submission]
      end
    }
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Common interpolation methods.
  #
  # @see #generate_interpolation_table
  #
  # === Implementation Notes
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
    # @param [any, nil] model         Model
    # @param [Hash]     opt
    #
    # @return [String, nil]
    #
    # @see Record::Identification#id_value
    #
    # @note Currently unused.
    # :nocov:
    def describe_id(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      id_value(model, **opt)
    end
    # :nocov:

    # A replacement value for '%{repo}' or '%{repository}' in #sprintf formats.
    #
    # @param [any, nil] model         Model
    # @param [Hash]     opt
    #
    # @return [String, nil]
    #
    # @see Record::EmmaIdentification#repository_name
    #
    # @note Currently unused.
    # :nocov:
    def describe_repo(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      repo = repository_value(model)
      repository_name(repo || opt)
    end
    # :nocov:

    # A replacement value for '%{sid}' in #sprintf formats.
    #
    # @param [any, nil] model         Model
    # @param [Hash]     opt
    #
    # @return [String, nil]
    #
    # @see Record::EmmaIdentification#sid_value
    #
    # @note Currently used only by #describe_submission.
    # :nocov:
    def describe_sid(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      sid_value(model, **opt)
    end
    # :nocov:

    # A replacement value for '%{submission}' in #sprintf formats.
    #
    # @param [any, nil] model         Model
    # @param [Hash]     opt
    #
    # @return [String, nil]
    #
    # @see Record::EmmaIdentification#sid_value
    #
    # @note Currently unused.
    # :nocov:
    def describe_submission(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      sid = describe_sid(model, **opt)
      config_term(:record, :submission, sid: sid.inspect)
    end
    # :nocov:

    # A replacement value for '%{user}' in #sprintf formats.
    #
    # @param [any, nil] model         Model
    # @param [Hash]     _opt          Unused.
    #
    # @return [String, nil]
    #
    # @note Currently unused.
    # :nocov:
    def describe_user(model = nil, **_opt)
      model ||= self_for_instance_method(__method__)
      user = model.try(:user) and User.account_name(user)
    end
    # :nocov:

    # A replacement value for '%{user_id}' in #sprintf formats.
    #
    # @param [any, nil] model         Model
    # @param [Hash]     _opt          Unused.
    #
    # @return [String, nil]
    #
    # @see User#id_value
    #
    # @note Currently unused.
    # :nocov:
    def describe_user_id(model = nil, **_opt)
      model ||= self_for_instance_method(__method__)
      user = model.try(:user) and User.id_value(user)
    end
    # :nocov:

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A textual description of the type of the Model instance for use as a
    # replacement value for '%{text}' in #sprintf formats.
    #
    # @param [any, nil] model         Model
    # @param [Hash]     opt
    #
    # @return [String]
    #
    # === Usage Notes
    # The including class is expected to define an overriding class method.
    #
    # @note Currently unused.
    # :nocov:
    def describe_type(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      model.class.send(__method__, model, **opt)
    end
    # :nocov:

    # A textual description of the status of the Model instance.
    #
    # @param [any, nil] model         Model
    # @param [Hash]     opt
    #
    # @return [String]
    #
    # === Usage Notes
    # The including class is expected to define an overriding class method.
    #
    # @note Currently unused.
    # :nocov:
    def describe_status(model = nil, **opt)
      model ||= self_for_instance_method(__method__)
      model.class.send(__method__, model, **opt)
    end
    # :nocov:

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
    # @note Currently used only by unused methods.
    # :nocov:
    def self_for_instance_method(meth)
      return self unless self.is_a?(Class)
      raise "#{meth}: *model* param required for class method"
    end
    # :nocov:

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
    # @note Currently unused.
    # :nocov:
    def interpolation_methods(&blk)
      new_module =
        module_eval <<~HEREDOC
          module InterpolationMethods
            include Record::Describable::InterpolationMethods
            extend self
          end
        HEREDOC
      new_module.module_exec(&blk)
      include new_module
      extend  new_module
    end
    # :nocov:

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
    # :nocov:
    def interpolation_table
      self.class.send(__method__)
    end
    # :nocov:

    # @see Record::Describable#interpolations
    # :nocov:
    def interpolations(text, model = nil, **opt)
      model ||= self
      super
    end
    # :nocov:
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

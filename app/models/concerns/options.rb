# app/models/concerns/options.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Options that may be specific to the originating controller.
#
# === Usage Notes
# Subclasses are expected to be defined lexically within their associated
# model class (which allows #model_class to be resolved automatically).
# Alternatively the subclass can define a MODEL constant to explicitly define
# the associated model class.
#
class Options

  include Emma::Json
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters involved in pagination.
  #
  # @type [Array<Symbol>]
  #
  PAGE_KEYS = %i[page start offset limit].freeze

  # URL parameters involved in form submission.
  #
  # @type [Array<Symbol>]
  #
  FORM_KEYS = %i[field-group cancel].freeze

  # POST/PUT/PATCH parameters from the entry form that are not relevant to the
  # create/update of a model instance.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_FORM_KEYS = (PAGE_KEYS + FORM_KEYS).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new options object.
  #
  # @param [Hash, nil] prm
  #
  def initialize(prm = nil)
    @params = prm&.dup || {}
    @value  = {}
    super()
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The model class associated with these options.
  #
  # @type [Class]
  #
  def self.model_class
    # noinspection RbsMissingTypeSignature
    @model_class ||= safe_const_get(:MODEL, false) || module_parent
  end

  # The parameter key denoting a collection of model field values in URL
  # parameters.
  #
  # @type [Symbol]
  #
  def self.model_key
    # noinspection RbsMissingTypeSignature
    @model_key ||=
      model_class.try(__method__) || model_class.model_name.singular.to_sym
  end

  # The parameter key denoting the identity of a model instance in URL
  # parameters.
  #
  # @type [Symbol]
  #
  def self.model_id_key
    # noinspection RbsMissingTypeSignature
    @model_id_key ||= model_class.try(__method__) || :"#{model_key}_id"
  end

  delegate :model_class, :model_key, :model_id_key, to: :class

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item is a valid option.
  #
  # @param [Symbol, String] key
  #
  def option?(key)
    key = key&.to_sym
    @value.key?(key) || option_method(key).present?
  end

  # Get an option value.
  #
  # @param [Symbol, String] key
  # @param [Boolean]        log   If *false* do not warn about bad keys.
  #
  # @return [any, nil]
  #
  def get(key, log: true)
    key = key&.to_sym
    if @value.key?(key)
      @value[key]
    elsif (meth = option_method(key))
      @value[key] = send(meth)
    elsif log
      Log.warn("#{self.class}[#{key.inspect}]: invalid key")
    end
  end

  # Set an option value.
  #
  # @param [Symbol, String] key
  # @param [any, nil]       value
  #
  # @return [any, nil]
  #
  def set(key, value)
    @value[key.to_sym] = value if key
  end

  # Fill @value with all option settings from defaults and supplied URL params.
  #
  # @param [Boolean] clean            If *true*, remove option parameters from
  #                                     the local copy of URL parameters.
  # @param [Hash]    opt              Passed to #get.
  #
  # @return [Hash]                    Updated option values.
  #
  def all(clean: false, **opt)
    keys = option_keys.each { get(_1, **opt) }
    @params.except!(*keys) if clean
    @value
  end

  alias :[]  :get
  alias :[]= :set

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters associated with item/entry identification.
  #
  # @type [Array<Symbol>]
  #
  def identifier_keys
    @identifier_keys ||= [:selected, model_id_key, :id].uniq
  end

  # URL parameters associated with POST data.
  #
  # @type [Array<Symbol>]
  #
  def data_keys
    @data_keys ||= [model_key]
  end

  # The valid option keys defined by the subclass.
  #
  # @return [Array<Symbol>]
  #
  def option_keys
    []
  end

  # The method associated with the given option key.
  #
  # @param [any, nil] key             String, Symbol
  #
  # @return [Symbol, nil]
  #
  def option_method(key)
    # noinspection RubyMismatchedArgumentType
    key.to_sym if (key.is_a?(Symbol) || key.is_a?(String)) && respond_to?(key)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Supplied URL parameters.
  #
  # @note This method is expected by ParamsHelper.
  #
  # @return [Hash]
  #
  def params
    @params
  end

  # URL parameters relevant to the associated model/controller.
  #
  # @note This method is expected by Record::Properties#parameters.
  #
  # @return [Hash]
  #
  def model_params
    @model_params ||= get_model_params
  end

  # Get URL parameters relevant to the current operation.
  #
  # @return [Hash]
  #
  def get_model_params
    prm = url_parameters(params)
    prm.except!(*ignored_form_params)
    prm[:id] = prm.delete(:selected) || prm[:id]
    prm.deep_symbolize_keys!
  end

  # Extract POST parameters that are usable for creating/updating a new model
  # instance.
  #
  # @return [Hash]
  #
  def model_post_params
    prm = model_params
    extract_model_data!(prm)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # ignored_form_params
  #
  # @return [Array<Symbol>]
  #
  def ignored_form_params
    IGNORED_FORM_KEYS
  end

  # model_data_params
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  def model_data_params
    {}
  end

  # Extract POST parameters that are usable for creating/updating an Upload
  # instance.
  #
  # @param [Hash]    prm              Parameters to update
  # @param [Boolean] compact          If *false*, allow blanks.
  # @param [Hash]    opt              Options to #json_parse.
  #
  # @return [Hash]                    The possibly-modified *prm*.
  #
  def extract_model_data!(prm, compact: true, **opt)
    opt[:log] = false unless opt.key?(:log)
    fields = prm.delete(model_key)
    if (fields &&= json_parse(fields, **opt))
      model_data_params.each_pair do |hash_key, url_param|
        value = fields.delete(hash_key)
        prm[url_param] = json_parse(value, **opt) if value
      end
      prm.merge!(fields)
    end
    compact ? reject_blanks!(prm) : prm
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  def inspect
    all # Force @value to be updated with all option settings.
    props = %i[model_key model_id_key]
    props = props.map { [_1, send(_1)] }.to_h
    props = props.map { "#{_1}=#{_2.inspect}" }.join(' ')
    vars  = %i[@value @model_params @params]
    vars  = vars.map { [_1, instance_variable_get(_1)] }.to_h
    vars  = vars.map { "#{_1}=#{_2.inspect}" }.join(' ')
    "#<#{self.class.name}:#{object_id} #{props} #{vars}>"
  end

end

__loading_end(__FILE__)

# app/models/concerns/options.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Options that may be specific to the the originating controller.
#
class Options

  include Emma::Json
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters associated with item/entry identification.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = %i[id selected].freeze

  # URL parameters associated with POST data.
  #
  # @type [Array<Symbol>]
  #
  DATA_PARAMS = [].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters involved in pagination.
  #
  # @type [Array<Symbol>]
  #
  PAGE_PARAMS = %i[page start offset limit].freeze

  # URL parameters involved in form submission.
  #
  # @type [Array<Symbol>]
  #
  FORM_PARAMS = %i[selected field-group cancel].freeze

  # POST/PUT/PATCH parameters from the entry form that are not relevant to the
  # create/update of a model instance.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_FORM_PARAMS = (PAGE_PARAMS + FORM_PARAMS).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The associated model type.
  #
  # @return [Symbol]
  #
  attr_reader :model

  # Create a new options object.
  #
  # @param [Symbol, any] model
  # @param [Hash, nil]   prm
  #
  def initialize(model, prm = nil)
    unless model.is_a?(Symbol)
      model = model.class unless model.is_a?(Module)
      model = model.to_s.underscore.sub(%r{[_/].*}, '').to_sym
    end
    @model  = model
    @params = prm&.dup || {}
    @value  = {}
    super()
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item is a valid option.
  #
  # @param [Symbol, String] key
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def key?(key)
    key = key&.to_sym
    @value.key?(key) || option_method(key).present?
  end

  # Get an option value.
  #
  # @param [Symbol, String] key
  # @param [Boolean]        log   If *false* do not warn about bad keys.
  #
  # @return [Any, nil]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
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
  # @param [Any, nil]       value
  #
  # @return [Any, nil]
  #
  def set(key, value)
    key = key&.to_sym
    @value[key] = value
  end

  # Fill @value with all option settings from defaults and supplied URL params.
  #
  # @param [Boolean] clean            If *true*, remove option parameters from
  #                                     the local copy of URL parameters.
  # @param [Hash]    opt              Passed to #get.
  #
  # @return [Hash{Symbol=>Any}]       Updated option values.
  #
  def all(clean: false, **opt)
    keys = option_keys.each { |key| get(key, **opt) }
    @params.except!(*keys) if clean
    @value
  end

  alias :[]  :get
  alias :[]= :set

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The valid option keys defined by the subclass.
  #
  # @return [Array<Symbol>]
  #
  def option_keys
    []
  end

  # The method associated with the given option key.
  #
  # @param [Symbol, String]
  #
  # @return [Symbol, nil]
  #
  def option_method(key)
    key = key&.to_sym
    key if respond_to?(key)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Supplied URL parameters.
  #
  # @note This method will be used in ParamsHelper.
  #
  # @return [Hash{Symbol=>*}]
  #
  def params
    @params
  end

  # URL parameters relevant to the associated model/controller.
  #
  # @note This method will be used by Record::Properties#parameters.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def model_params
    @model_params ||= get_model_params
  end

  # Get URL parameters relevant to the current operation.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>Any}]
  #
  def get_model_params(p = nil)
    prm = url_parameters(p)
    prm.except!(*ignored_form_params)
    prm.deep_symbolize_keys!
    reject_blanks(prm)
  end

  # Extract POST parameters that are usable for creating/updating a new model
  # instance.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `Options#params`
  #
  # @return [Hash{Symbol=>Any}]
  #
  def model_post_params(p = nil)
    prm = p ? get_model_params(p) : model_params
    extract_model_data!(prm) || prm
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
    IGNORED_FORM_PARAMS
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
  # @param [Hash] prm         Parameters to update
  # @param [Hash] opt         Options to #json_parse.
  #
  # @return [Hash, nil]       The new contents of *prm* if modified.
  #
  def extract_model_data!(prm, **opt)
    opt[:log] = false unless opt.key?(:log)
    # @type [Hash, nil]
    fields = json_parse(prm.delete(model), **opt) or return
    model_data_params.each_pair do |hash_key, url_param|
      prm[url_param] = json_parse(fields.delete(hash_key), **opt)
    end
    prm.merge!(fields)
    reject_blanks(prm)
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  def inspect
    all # Force @value to be updated with all option settings.
    vars = %w(@model @value @model_params @params)
    vars.map! { |var| "#{var}=%s" % instance_variable_get(var).inspect }
    "#<#{self.class.name}:#{object_id} %s>" % vars.join(' ')
  end

end

__loading_end(__FILE__)

# app/services/submission_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SubmissionService::Properties
#
module SubmissionService::Properties

  include ApiService::Properties
  include Record::Properties # TODO: This may need to change...
  include Emma::TimeMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  COMMANDS = %i[start cancel pause resume list].freeze

  # Configuration for all submission services.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  CONFIGURATION =
    I18n.t('emma.service.submission').transform_values { |config|
      if config.is_a?(Hash)
        config.dup.tap do |cfg|
          cfg[:timeout]  = positive_float(cfg[:timeout]).to_f * SECONDS
          cfg[:priority] = positive(cfg[:priority])
        end
      else
        config
      end
    }.deep_freeze

  # How important an external service is as an authority for the type(s) of
  # identifiers it can search.  For example:
  #
  # * 1   High
  # * 10  Medium
  # * 100 Low
  #
  # @type [Integer]
  #
  # @see SubmissionService#SERVICE_TABLE
  #
  DEFAULT_PRIORITY = CONFIGURATION.dig(:_template, :priority)

  # How long to wait for a response from the external service.
  #
  # @type [Float]
  #
  DEFAULT_TIMEOUT = CONFIGURATION.dig(:_template, :timeout)

  # How many manifest items to process in a single job.
  #
  # If *true*, items will be partitioned into batches - as few as possible.
  # If *false* then items will be submitted sequentially.
  #
  # @type [Integer, Boolean]
  #
  DEF_BATCH_SIZE = 8 # TODO: remove - testing
=begin
  DEF_BATCH_SIZE = BATCH_SIZE_DEFAULT
=end

  # Batching is not actually performed if the number of manifest items is less
  # than this number.
  #
  # @type [Integer]
  #
  MIN_BATCH_SIZE = 2

  MAX_BATCH_SIZE = 10 # TODO: remove - testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The configuration key for the service.
  #
  # @return [Symbol]
  #
  def service_key
    (is_a?(Module) ? name : self.class.name).demodulize.underscore.to_sym
  end

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # Configuration for the API service.
  #
  # @type [Hash{Symbol=>Any}]
  #
  def configuration
    CONFIGURATION[service_key]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # How important the external service is as an authority for the type(s) of
  # identifiers it can search.
  #
  # @type [Integer]
  #
  # @see SubmissionService::Properties#DEFAULT_PRIORITY
  #
  def priority
    configuration[:priority] || DEFAULT_PRIORITY
  end

  # How long to wait for a response from the external service.
  #
  # @return [Float]
  #
  # @see SubmissionService::Properties#DEFAULT_TIMEOUT
  #
  def timeout
    configuration[:timeout] || DEFAULT_TIMEOUT
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # batch_option
  #
  # @param [Numeric, Boolean, nil] value
  # @param [Integer, Boolean, nil] default
  #
  # @return [Integer, nil]
  #
  def batch_option(value, default = DEF_BATCH_SIZE)
    return                if value == false
    return MAX_BATCH_SIZE if value == true
    positive(value) || ((default == true) ? MAX_BATCH_SIZE : positive(default))
  end

  # timeout_option
  #
  # @param [Numeric, Boolean, nil] value
  # @param [Float]                 default
  #
  # @return [Float, nil]
  #
  def timeout_option(value, default = DEFAULT_TIMEOUT)
    numeric_option(value, default)
  end

  # numeric_option
  #
  # @param [Numeric, Boolean, nil] val
  # @param [Integer, Float, nil]   default
  #
  # @return [Integer, Float, nil]
  #
  def numeric_option(val, default = nil)
    return if val.is_a?(FalseClass)
    (default.is_a?(Integer) ? positive(val) : positive_float(val)) || default
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the batch size indicated by the value.
  #
  # The result will be *nil* or in the range [#MIN_BATCH_SIZE..#MAX_BATCH_SIZE]
  #
  # @param [Numeric, Boolean, nil] value
  # @param [Array, nil]            items
  #
  # @return [Integer, nil]
  #
  def batch_size_for(value, items = nil)
    batch = batch_option(value) or return
    batch = [batch, MAX_BATCH_SIZE].min
    batch = [batch, items.size].min if (items &&= extract_items(items))
    batch unless batch < MIN_BATCH_SIZE
  end

  # extract_manifest_id
  #
  # @param [*]    arg
  # @param [Hash] opt
  #
  # @return [String, nil]
  #
  def extract_manifest_id(arg = nil, **opt)
    arg = arg.deep_symbolize_keys if arg.is_a?(Hash)
    arg = arg.merge(opt)          if arg.is_a?(Hash)
    arg = opt                     if arg.nil?
    arg = arg.first               if arg.is_a?(Array)
    # noinspection RubyMismatchedReturnType
    case arg
      when SubmissionService::Request  then arg[:manifest_id]
      when SubmissionService::Response then arg.manifest_id
      when ManifestItem                then arg.manifest_id
      when Manifest                    then arg.id
      when String                      then arg unless positive(arg)
      when Hash                        then arg[:manifest] || arg[:manifest_id]
    end
  end

  # extract_items
  #
  # @param [*]           arg
  # @param [Symbol, nil] scope
  # @param [Hash]        opt
  #
  # @return [Array<String>]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def extract_items(arg = nil, scope: nil, **opt)
    arg = arg.deep_symbolize_keys if arg.is_a?(Hash)
    arg = arg.merge!(opt)         if arg.is_a?(Hash)
    arg = opt                     if arg.nil?
    arg = arg.items               if arg.respond_to?(:items)

    arg = arg.values_at(:items,:manifest,:manifest_id).first if arg.is_a?(Hash)

    arg = Manifest.find(arg)      if arg.is_a?(String) && !positive(arg)
    arg = arg.manifest_items      if arg.is_a?(Manifest)
    arg = arg.send(scope)         if arg.is_a?(ActiveRecord::Relation) && scope
    arg = arg.to_a                if arg.is_a?(ActiveRecord::Relation)
    arg = arg.fields              if arg.is_a?(ManifestItem)

    return arg.map { |a| extract_items(a) }.flatten.compact if arg.is_a?(Array)

    case arg
      when SubmissionService::Request  then Array.wrap(arg[:manifest_id])
      when SubmissionService::Response then Array.wrap(arg.manifest_id)
      when ManifestItem                then Array.wrap(arg.id)
      when Hash                        then Array.wrap(arg[:id])
      else                                  Array.wrap(positive(arg))
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)

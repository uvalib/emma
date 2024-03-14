# app/services/submission_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SubmissionService::Properties
#
module SubmissionService::Properties

  include ApiService::Properties
  include Record::Properties
  include Emma::Common
  include Emma::TimeMethods

  # ===========================================================================
  # :section: Configuration
  # ===========================================================================

  public

  COMMANDS = %i[start cancel pause resume list].freeze

  # Configuration for all submission services.
  #
  # @type [Hash]
  #
  CONFIGURATION =
    config_section('emma.service.submission').transform_values { |config|
      if config.is_a?(Hash)
        config.dup.tap do |cfg|
          cfg[:timeout]  = positive_float(cfg[:timeout]).to_f * SECONDS
          cfg[:priority] = positive(cfg[:priority])
        end
      else
        config
      end
    }.deep_freeze

  # Service default property configuration.
  #
  # @type [Hash]
  #
  SERVICE_PROPERTY =
    CONFIGURATION
      .reject { |_, v| v.is_a?(Hash) }
      .reverse_merge!(CONFIGURATION[:_template] || {})
      .freeze

  # How important an external service is as an authority for the type(s) of
  # identifiers it can search.  For example:
  #
  # * 1   High
  # * 10  Medium
  # * 100 Low
  #
  # @type [Integer]
  #
  DEFAULT_PRIORITY = SERVICE_PROPERTY[:priority].to_i

  # How long to wait for a response from the external service.
  #
  # @type [Float]
  #
  DEFAULT_TIMEOUT = SERVICE_PROPERTY[:timeout].to_f

  # ===========================================================================
  # :section: Configuration - batch size
  # ===========================================================================

  public

  # Batching is not actually performed if the number of manifest items is less
  # than this number.
  #
  # @type [Integer]
  #
  # @see "en.emma.service.submission.batch_min"
  # @see "en.emma.service.submission._template.batch_min"
  #
  MIN_BATCH = SERVICE_PROPERTY[:batch_min]&.to_i || 1

  # Batches larger than this number are not permitted.
  #
  # @type [Integer]
  #
  # @see "en.emma.service.submission.batch_max"
  # @see "en.emma.service.submission._template.batch_max"
  #
  MAX_BATCH = SERVICE_PROPERTY[:batch_max]&.to_i || MAX_BATCH_SIZE

  # How many manifest items to process in a single job.
  #
  # If *true*, items will be partitioned into batches - as few as possible.
  # If *false* then items will be submitted sequentially.
  #
  # @type [Integer, Boolean]
  #
  DEF_BATCH = SERVICE_PROPERTY[:batch_size].then do |v|
    case v
      when Integer then v
      when nil     then BATCH_SIZE_DEFAULT
      else              true?(v)
    end
  end

  if sanity_check?
    def_batch = DEF_BATCH.is_a?(Integer) ? DEF_BATCH : MIN_BATCH
    raise 'MIN_BATCH > MAX_BATCH'         if MIN_BATCH > MAX_BATCH
    raise 'MAX_BATCH > BATCH_UPPER_BOUND' if MAX_BATCH > BATCH_UPPER_BOUND
    raise 'DEF_BATCH < MIN_BATCH'         if def_batch < MIN_BATCH
    raise 'DEF_BATCH > MAX_BATCH'         if def_batch > MAX_BATCH
  end

  # ===========================================================================
  # :section: Configuration - slice size
  # ===========================================================================

  public

  # Minimum slice size.
  #
  # @type [Integer]
  #
  # @see "en.emma.service.submission.slice_min"
  # @see "en.emma.service.submission._template.slice_min"
  #
  MIN_SLICE = SERVICE_PROPERTY[:slice_min]&.to_i || MIN_BATCH

  # Maximum slice size.
  #
  # @type [Integer]
  #
  # @see "en.emma.service.submission.slice_max"
  # @see "en.emma.service.submission._template.slice_max"
  #
  MAX_SLICE = SERVICE_PROPERTY[:slice_max]&.to_i || MAX_BATCH

  # Within a given batch of ManifestItems being submitted, this value specifies
  # how many will be transmitted together to each subsystem.
  #
  # If *true*, all items of a batch will be transmitted together if possible.
  # If *false* then no slicing will be performed by default.
  #
  # @type [Integer, Boolean]
  #
  # @see "en.emma.service.submission.slice_size"
  # @see "en.emma.service.submission._template.slice_size"
  #
  DEF_SLICE = SERVICE_PROPERTY[:slice_size].then do |v|
    case v
      when Integer then v
      when nil     then !DEF_BATCH.is_a?(Integer) || (DEF_BATCH / 2)
      else              true?(v)
    end
  end

  if sanity_check?
    def_slice = DEF_SLICE.is_a?(Integer) ? DEF_SLICE : MIN_SLICE
    raise 'MIN_SLICE < MIN_BATCH' if MIN_SLICE < MIN_BATCH
    raise 'MAX_SLICE > MAX_BATCH' if MAX_SLICE > MAX_BATCH
    raise 'DEF_SLICE < MIN_SLICE' if def_slice < MIN_SLICE
    raise 'DEF_SLICE > MAX_SLICE' if def_slice > MAX_SLICE
  end

  # ===========================================================================
  # :section: Configuration - simulation
  # ===========================================================================

  public

  SIMULATION_ALLOWED = true
  SIMULATION_ONLY    = false

  if sanity_check?
    raise 'SIMULATION_ONLY invalid' if SIMULATION_ONLY && !SIMULATION_ALLOWED
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All bulk submission steps, including non-actionable "pseudo steps" and
  # client-side-only steps.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SUBMIT_STEPS_TABLE =
    config_section('emma.bulk.step').map { |step, entry|
      entry = entry.dup
      entry[:label]   ||= "#{step} status".titleize
      entry[:css]     ||= "#{step}-status"
      entry[:client]    = !false?(entry[:client])
      entry[:server]    = !false?(entry[:server])
      entry[:sim_msg] ||= step.to_s
      entry[:sim_err] ||= step.to_s
      [step.to_sym, entry]
    }.to_h.deep_freeze

 #CLIENT_STEPS = SUBMIT_STEPS_TABLE.select { |_, v| v[:client] }.keys.freeze
  SERVER_STEPS = SUBMIT_STEPS_TABLE.select { |_, v| v[:server] }.keys.freeze

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
  def batch_option(value, default = DEF_BATCH)
    return           if value == false
    return MAX_BATCH if value == true
    positive(value) || positive(default) || (MAX_BATCH if default)
  end

  # slice_option
  #
  # @param [Numeric, Boolean, nil] value
  # @param [Integer, Boolean, nil] default
  #
  # @return [Integer, nil]
  #
  def slice_option(value, default = DEF_SLICE)
    return           if value == false
    return MAX_SLICE if value == true
    positive(value) || positive(default) || (MAX_SLICE if default)
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
  # The result will be *nil* or in the range [#MIN_BATCH..#MAX_BATCH].
  #
  # @param [Numeric, Boolean, nil] value
  # @param [Array, nil]            items
  #
  # @return [Integer, nil]
  #
  def batch_size_for(value, items = nil)
    batch = batch_option(value) or return
    batch = [batch, MAX_BATCH].min
    batch = [batch, items.size].min if (items &&= extract_items(items))
    batch unless batch < MIN_BATCH
  end

  # extract_manifest_id
  #
  # @param [any, nil] arg
  # @param [Hash]     opt
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
      when SubmissionService::Response then arg[:manifest_id]
      when SubmissionService::Request  then arg.manifest_id
      when ManifestItem                then arg.manifest_id
      when Manifest                    then arg.id
      when String                      then arg unless positive(arg)
      when Hash                        then arg[:manifest] || arg[:manifest_id]
    end
  end

  # extract_items
  #
  # @param [any, nil]    arg
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
      when SubmissionService::Response then Array.wrap(arg[:manifest_id])
      when SubmissionService::Request  then Array.wrap(arg.manifest_id)
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

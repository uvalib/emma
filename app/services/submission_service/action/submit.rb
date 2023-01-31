# app/services/submission_service/action/submit.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SubmissionService::Action::Submit
#
module SubmissionService::Action::Submit

  include SubmissionService::Common
  include SubmissionService::Definition

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  SUBMIT_STEPS_TABLE = {
    db: {
      msg:  'mark ManifestItem as being submitted',
      err:  'DB',
    },
    cache: {
      msg:  'upload file to AWS cache',
      err:  'AWS upload',
    },
    promote: {
      msg:  'promote file to AWS storage',
      err:  'AWS storage',
    },
    index: {
      msg:  'update index',
      err:  'index',
    },
  }.deep_freeze

  SUBMIT_STEPS = SUBMIT_STEPS_TABLE.keys.freeze

  # Within a given batch of ManifestItems being submitted, this value specifies
  # how many will be transmitted together to each subsystem.
  #
  # If *true*, all items of a batch will be transmitted together if possible.
  # If *false* then no slicing will be performed by default.
  #
  # @type [Integer, Boolean]
  #
  DEF_SLICE = 4
  MIN_SLICE = MIN_BATCH_SIZE
  MAX_SLICE = MAX_BATCH_SIZE

  if sanity_check? && DEF_SLICE.is_a?(Integer)
    raise 'DEF_SLICE < MIN_SLICE' if DEF_SLICE < MIN_SLICE
    raise 'DEF_SLICE > MAX_SLICE' if DEF_SLICE > MAX_SLICE
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Receive a request to start batch creation of EMMA entries.
  #
  # @param [SubmissionService::Request, nil] request
  # @param [Manifest, String]                manifest
  # @param [Array<ManifestItem>, nil]        items
  # @param [Hash]                            opt      To #post_flight except:
  #
  # @option opt [Integer] :slice
  #
  # @return [SubmissionService::SubmitResponse] The value assigned to @result.
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def batch_create(request = nil, manifest: nil, items: nil, **opt)
    self.request      = request ||= pre_flight(manifest, items, **opt)
    self.start_time   = request[:start_time]  ||= timestamp
    opt[:manifest_id] = request[:manifest_id] ||= manifest
    result_data       = submit_batch(**opt)
    self.end_time     = timestamp
    self.result       = post_flight(result_data, **opt)
  end

  # Receive a request to start batch modification of EMMA entries.
  #
  # @param [SubmissionService::Request, nil] request
  # @param [Manifest, String]                manifest
  # @param [Array<ManifestItem>, nil]        items
  # @param [Hash]                            opt      To #post_flight except:
  #
  # @option opt [Integer] :slice
  #
  # @return [SubmissionService::SubmitResponse] The value assigned to @result.
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def batch_update(request = nil, manifest: nil, items: nil, **opt)
    self.request      = request ||= pre_flight(manifest, items, **opt)
    self.start_time   = request[:start_time]  ||= timestamp
    opt[:manifest_id] = request[:manifest_id] ||= manifest
    result_data       = submit_batch(**opt)
    self.end_time     = timestamp
    self.result       = post_flight(result_data, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Submit a set of items...
  #
  # @param [SubmissionService::Request] req  Def.: `@request`.
  # @param [Hash]                       opt
  #
  # @return [Array<Hash>, Hash]
  #
  def submit_batch(req = self.request, **opt)
    opt[:tid] = Thread.current.name.sub(/^GoodJob.*\)-thread/, 'GoodJob')
    opt[:manifest_id] = req.manifest_id

    slice = opt.delete(:slice)
    slice = DEF_SLICE      if slice.nil?
    slice = req.items.size if slice.is_a?(TrueClass)
    slice = false          if slice && (slice < MIN_SLICE)
    slice = MAX_SLICE      if slice && (slice > MAX_SLICE)

    # noinspection RubyMismatchedArgumentType
    if slice
      submit_by_slice(req, **opt, slice: slice)
    else
      submit_by_item(req, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Submit a set of items one at a time.
  #
  # @param [SubmissionService::Request] req  Def.: `@request`.
  # @param [Hash]                       opt
  #
  # @return [Array<Hash>]
  #
  def submit_by_item(req = self.request, **opt)
    sleep rand(0.1..0.3)
    opt[:no_raise] = true
    req.items.map do |item|
      # noinspection RubyMismatchedArgumentType
      if (id = manifest_item_id(item)).is_a?(Hash)
        err = id[:error]
        id  = 'missing'
      else
        err = submit_manifest_item(id, **opt)
        err = (err.values.last if err.is_a?(Hash))
      end
      if err
        { id: id, status: '(FAIL)', error: err }
      else
        { id: id, status: '(OK)' }
      end
    end
  end

  # submit_manifest_item
  #
  # @param [String]  item
  # @param [Boolean] no_raise
  # @param [Hash]    opt
  #
  # @raise [RuntimeError] If a step failed.
  #
  # @return [true]        If all steps succeeded.
  # @return [Hash]        If *no_raise* and a step failed.
  #
  def submit_manifest_item(item, no_raise: false, **opt)
    scale = opt[:scale] ||= 100
    band  = opt[:band]  ||= scale / 10
    opt[:state] ||= rand * scale
    opt[:work]  ||= 0.05..0.15
    opt[:meth]  ||= __method__

    delay = opt.delete(:delay) || 0.1..0.3
    delay = rand(delay) if delay.is_a?(Range)
    sleep delay if delay

    SUBMIT_STEPS.each_with_index do |step, i|
      range = (i*band)...((i+1)*band)
      submit_manifest_item_step(item, **opt, range: range, step: step)
    end

    opt.merge!(msg: 'unmark ManifestItem as being submitted', err: nil)
    submit_manifest_item_step(item, **opt)
    true

  rescue error
    raise error unless no_raise
    { item => error.to_s }
  end

=begin
  def submit_db_step(item, **opt)
    opt[:meth] ||= __method__
    submit_manifest_item_step(item, **opt, step: :db)
  end

  def submit_cache_step(item, **opt)
    opt[:meth] ||= __method__
    submit_manifest_item_step(item, **opt, step: :cache)
  end

  def submit_promote_step(item, **opt)
    opt[:meth] ||= __method__
    submit_manifest_item_step(item, **opt, step: :promote)
  end

  def submit_index_step(item, **opt)
    opt[:meth] ||= __method__
    submit_manifest_item_step(item, **opt, step: :index)
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Submit a set of items in slices to each step.
  #
  # @param [SubmissionService::Request] req  Def.: `@request`.
  # @param [Integer]                    slice
  # @param [Hash]                       opt
  #
  # @return [Hash]
  #
  def submit_by_slice(req = self.request, slice:, **opt)
    opt[:delay] ||= 0.1..0.3
    opt[:work]  ||= 0.2..0.4

    items = req.items.map { |item| manifest_item_id(item) }
    valid_items, invalid_items = items.partition { |item| item.is_a?(String) }
    valid_items.sort!.uniq!
    invalid_items.map! { |entry| entry[:error] }

    success_items, failure_items = [], []
    valid_items.each_slice(slice) do |succeeded|
      SUBMIT_STEPS.each do |step|
        next if succeeded.blank?
        # noinspection RubyMismatchedArgumentType
        succeeded, failed = submit_manifest_items(succeeded, **opt, step: step)
        success_items += succeeded
        failure_items += failed
      end
    end
    success_items.sort!.uniq!
    failure_items  = failure_items.sort!.to_h
    success_items -= failure_items.keys

    # NOTE: SubmissionService::StepResponse::TEMPLATE[:data]
    {
      count:      items.size,
      submitted:  valid_items,
      success:    success_items,
      failure:    failure_items.presence,
      invalid:    invalid_items.presence,
    }.compact
  end

  # submit_manifest_items
  #
  # @param [Array<String>] items
  # @param [Boolean]       sort
  # @param [Boolean]       no_raise
  # @param [Hash]          opt
  #
  # @return [(Array<String>, Array<Array<(String,String)>>)]
  #
  def submit_manifest_items(items, sort: false, no_raise: true, **opt)
    success, failure = [], []
    if items.present?
      result = submit_manifest_item_step(items, no_raise: no_raise, **opt)
      if result.is_a?(Hash)
        success = result.map { |k, v| k if v == :success }.compact
        failure = result.except(*success).map { |k, v| [k, v.to_s] }
      else
        success = result
      end
    end
  rescue => error
    raise error unless no_raise
    notice = error.to_s
    failure += items.map { |item| [item, notice] }
  ensure
    [success, failure].each(&:sort!) if sort
    return success, failure
  end

=begin
  def submit_db_slice(items, **opt)
    opt[:meth] ||= __method__
    submit_manifest_items(items, **opt, step: :db)
  end

  def submit_cache_slice(items, **opt)
    opt[:meth] ||= __method__
    submit_manifest_items(items, **opt, step: :cache)
  end

  def submit_promote_slice(items, **opt)
    opt[:meth] ||= __method__
    submit_manifest_items(items, **opt, step: :promote)
  end

  def submit_index_slice(items, **opt)
    opt[:meth] ||= __method__
    submit_manifest_items(items, **opt, step: :index)
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # manifest_item_id
  #
  # @param [ManifestItem, Hash, String, Integer, *] item
  #
  # @return [String]    If valid
  # @return [Hash]      If invalid
  #
  def manifest_item_id(item)
    result = error = nil
    case item
      when ManifestItem, Hash then result = item[:id]
      when String, Integer    then result = item
      else                         error  = "invalid item #{item.inspect}"
    end
    result&.to_s&.presence || { error: (error || "no ID for #{item.inspect}") }
  end

  # submit_manifest_item_step
  #
  # @param [String, Array<String>] item
  # @param [Symbol, nil]           step
  # @param [String, nil]           msg
  # @param [String, nil]           err
  # @param [Float, nil]            start_time
  # @param [String, nil]           tid
  # @param [String, nil]           tag
  # @param [Symbol, nil]           meth
  # @param [Boolean]               no_raise
  # @param [Proc, nil]             callback
  # @param [Numeric, Range]        delay
  # @param [Numeric, Range]        work
  # @param [Numeric]               scale
  # @param [Numeric]               band
  # @param [Numeric, Range]        range
  # @param [Numeric, Range]        state
  # @param [Hash]                  opt
  #
  # @option opt [String] manifest_id
  # @option opt [String] job_id
  #
  # @return [String, Array<String>]       Success(es)
  # @return [Hash,   Array<String,Hash>]  Failure(s)
  #
  def submit_manifest_item_step(
    item,
    step:       nil,
    msg:        nil,
    err:        nil,
    start_time: nil,
    tid:        nil,
    tag:        nil,
    meth:       nil,
    no_raise:   false,
    callback:   nil,
    delay:      nil,
    work:       nil,
    scale:      1,
    band:       0.1,
    range:      nil,
    state:      nil,
    **opt
  )
    result = success = failure = nil
    if (entry = step && SUBMIT_STEPS_TABLE[step])
      msg ||= entry[:msg]
      err ||= entry[:err]
    else
      raise "invalid step #{step.inspect}" if step
    end
    if err
      range ||= ((scale - band) / 2)...((scale + band) / 2)
      state ||= rand * scale
      err     = ("simulated #{err} failure".upcase if range.include?(state))
    end
    delay &&= rand(delay) if delay.is_a?(Range)
    work  &&= rand(work)  if work.is_a?(Range) # TODO: simulated work time
    msg   &&= "TODO: #{msg}"
    meth  ||= __method__
    tag   ||= ["*** SUBMIT --- #{self_class}.#{meth}"].tap { |parts|
      parts << "step = #{step}" if step
      parts << "tid = #{tid}"   if tid
      parts << (item.is_a?(Array) ? item.join(', ') : item)
    }.join(' | ')
    sleep delay if delay
    start_time ||= timestamp

    $stderr.puts "#{tag} | t = #{start_time} | #{err || msg}"
    raise err   if err   # NOTE: simulates operational failure
    sleep work  if work  # NOTE: simulates working time

    result = success = item

  rescue => error
    notice = error.to_s
    result =
      if item.is_a?(Array)
        success = Array.wrap(success)
        failure = Array.wrap(failure)
        item.map { |unit|
          state   = (:success if success.include?(unit))
          state ||= (:failure if failure.include?(unit))
          [unit, (state || notice)]
        }.to_h
      else
        { item => notice }
      end
    raise error unless no_raise

  ensure
    if callback
      if result.is_a?(Hash)
        success = result.map { |k, v| k if v == :success }.compact
        failure = result.except(*success)
      else
        success = Array.wrap(result)
        failure = []
      end
      items   = Array.wrap(item)
      message = opt.slice(:manifest_id, :job_id)
      message[:step]           = step
      message[:start_time]     = t_start = start_time
      message[:end_time]       = t_end   = timestamp
      message[:duration]       = duration(t_end, t_start, precision: 4)
      message[:data]           = { count: items.size, submitted: items }
      message[:data][:success] = success if success.present?
      message[:data][:failure] = failure if failure.present?
      callback.(message)
    end
    return result
  end

end

__loading_end(__FILE__)

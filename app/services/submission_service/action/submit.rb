# app/services/submission_service/action/submit.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SubmissionService::Action::Submit
#
module SubmissionService::Action::Submit

  include IngestConcern
  include ExecReport::Constants
  include FileNaming

  include SubmissionService::Common
  include SubmissionService::Definition
  include SubmissionService::Properties

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

  # Process a request to submit a set of ManifestItems.
  #
  # @param [SubmissionService::Request] req  Def.: `@request`.
  # @param [Hash]                       opt
  #
  # @return [StepResult]
  #
  # === Usage Notes
  # The validity of :simulation and :sim_opt is determined here only; called
  # methods assume that `opt[:simulation]` and `opt[:sim_opt]` have been
  # set/unset appropriately.
  #
  def submit_batch(req = self.request, **opt)
    opt[:manifest_id] ||= req.manifest_id

    # Handle validation/creation of simulation options (if configured).
    if SIMULATION_ALLOWED
      opt[:simulation] = true if SIMULATION_ONLY
    elsif opt[:simulation]
      raise "#{__method__}: simulation is disallowed"
    elsif opt[:sim_opt]
      Log.warn { "#{__method__}: ignoring sim_opt = #{opt[:sim_opt].inspect}" }
    end
    if opt[:simulation]
      opt[:sim_opt] ||= SimulationOptions.new
    else
      opt.delete(:sim_opt)
    end

    # Identify any supplied items that don't map on to a valid ManifestItem.
    valid_ids, invalid_ids = [], []
    items =
      req.items.map do |item|
        if (id = manifest_item_id(item)).is_a?(Hash)
          invalid_ids << id[:error]
          next
        elsif valid_ids.include?(id)
          Log.warn { "#{__method__}: duplicate item #{item.inspect}" }
        else
          valid_ids << id
          item
        end
      end
    items.compact!
    # noinspection RubyMismatchedReturnType
    items.sort_by! { |item| manifest_item_id(item) }

    # Claim submission IDs for the items that will persist through the point
    # that the item becomes associated with an EMMA entry.
    now  = DateTime.now
    recs = manifest_items(items)
    recs.each do |rec|
      attrs = { submission_id: ManifestItem.generate_submission_id(now) }
      attrs.merge!(last_indexed: nil, last_submit: nil) if opt[:simulation]
      rec.update_columns(attrs)
    end

    slice = opt.delete(:slice)
    slice = DEF_SLICE if slice.nil?
    slice = recs.size if slice.is_a?(TrueClass)
    slice = false     if slice && (slice < MIN_SLICE)
    slice = MAX_SLICE if slice && (slice > MAX_SLICE)
    slice = positive(slice)

    if slice
      result = submit_by_slice(recs, **opt, slice: slice)
    else
      result = submit_by_item(recs, **opt)
    end
    result[:count]     = req.items.size
    result[:submitted] = valid_ids.sort
    result[:invalid]   = invalid_ids if invalid_ids.present?
    result.finalize
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Process a request to submit a set of ManifestItems sequentially.
  #
  # Each item submission may succeed or fail independently without impact to
  # the other items.
  #
  # @param [String, ManifestItem, Array, ActiveRecord::Relation] items
  # @param [Hash]                                                opt
  #
  # @return [StepResult]
  #
  def submit_by_item(items, **opt)
    sim = opt[:sim_opt]
    sim&.new_slice
    success, failure = {}, {}
    manifest_items(items).each do |rec|
      result = submit_manifest_item(rec, **opt, fatal: false)
      s = result.success.presence and success.merge!(s)
      f = result.failure.presence and failure.merge!(f)
    end
    StepResult.new(success: success, failure: failure)
  end

  # Submit a single ManifestItem by passing it through each of the submission
  # steps in sequence.
  #
  # Failure at any step results in the failure of the item to be submitted.
  #
  # @param [String, ManifestItem] item
  # @param [Boolean]              fatal
  # @param [Hash]                 opt
  #
  # @raise [RuntimeError]             If a submission step failed.
  #
  # @return [StepResult]
  #
  def submit_manifest_item(item, fatal: true, **opt)
    recs, success, failure = [], {}, {}
    recs = manifest_items(item)
    sim  = opt[:sim_opt]
    sim&.new_item
    opt[:meth] ||= __method__
    SERVER_STEPS.each do |step|
      break if recs.empty?
      sim&.new_step
      result = submission_step(recs, **opt, step: step)
      s = result.success.presence and success.merge!(s)
      f = result.failure.presence and failure.merge!(f)
      recs.reject! { |rec| f.key?(manifest_item_id(rec)) } if f
    end
  rescue => error
    update_failures!(failure, error, recs)
    raise error if fatal
  ensure
    return StepResult.new(success: success, failure: failure)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Process a request to submit a set of ManifestItems by aggregating them into
  # "slices" which pass through submission steps together.
  #
  # The up side is that this reduces the number of transmissions to external
  # services; the down side is that a failure at any step results in the
  # failure of all items in that "slice".
  #
  # @param [String, ManifestItem, Array, ActiveRecord::Relation] items
  # @param [Integer]                                             slice
  # @param [Hash]                                                opt
  #
  # @return [StepResult]
  #
  def submit_by_slice(items, slice:, **opt)
    success, failure = {}, {}
    sim = opt[:sim_opt]
    manifest_items(items).each_slice(slice) do |recs|
      sim&.new_slice
      SERVER_STEPS.each do |step|
        break if recs.empty?
        sim&.new_step
        result = submit_manifest_items(recs, **opt, step: step)
        s = result.success.presence and success.merge!(s)
        f = result.failure.presence and failure.merge!(f)
        recs.reject! { |rec| f.key?(manifest_item_id(rec)) } if f
      end
    end
    success.except!(*failure.keys)
    StepResult.new(success: success, failure: failure)
  end

  # submit_manifest_items
  #
  # @param [String, ManifestItem, Array, ActiveRecord::Relation] items
  # @param [Symbol]                                              step
  # @param [Boolean]                                             fatal
  # @param [Hash]                                                opt
  #
  # @return [StepResult]
  #
  def submit_manifest_items(items, step:, fatal: false, **opt)
    recs, success, failure = [], {}, {}
    recs = manifest_items(items)
    submission_step(recs, fatal: fatal, **opt, step: step).tap do |res|
      s = res.success.presence and success.merge!(s)
      f = res.failure.presence and failure.merge!(f)
    end
  rescue => error
    update_failures!(failure, error, recs)
    raise error if fatal
  ensure
    return StepResult.new(success: success, failure: failure)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the array of ManifestItem expressed or implied by *items*.
  #
  # @param [String, ManifestItem, Array, ActiveRecord::Relation] items
  #
  # @return [Array<ManifestItem>]
  #
  def manifest_items(items)
    case (items.is_a?(Array) ? items.first : items).presence
      when nil                    then []
      when ActiveRecord::Relation then items.to_a
      when ManifestItem           then Array.wrap(items)
      else                             ManifestItem.where(id: items).to_a
    end
  end

  # Extract the ManifestItem identifier from *item* if possible.
  #
  # (For use in contexts where *item* may already be an identifier.)
  #
  # @param [any, nil] item            ManifestItem, Hash, Integer, String
  #
  # @return [String]    If valid
  # @return [Hash]      If invalid
  #
  def manifest_item_id(item)
    result = error = nil
    case item
      when ManifestItem then result = item.id
      when Hash         then result = item[:manifest_item_id] || item[:id]
      when Integer      then result = item.to_s
      when String       then result = item
      else                   error  = "invalid item #{item.inspect}"
    end
    result&.to_s&.presence || { error: (error || "no ID for #{item.inspect}") }
  end

  # Update all entries of a table of failure results with the given error.
  #
  # @param [Hash]                     failure
  # @param [Exception, String]        error
  # @param [Array<ManifestItem>, nil] recs
  #
  # @return [void]
  #
  def update_failures!(failure, error, recs = nil)
    msg = error.to_s
    ids = recs&.map { |rec| manifest_item_id(rec) } || failure.keys
    ids.each do |id|
      if !failure[id]
        failure[id] = { error: msg }
      elsif !failure[id].is_a?(Hash)
        failure[id] = { error: [*failure[id], msg].uniq.join('; ') }
      else
        failure[id][:error] = [*failure[id][:error], msg].uniq.join('; ')
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # submission_step
  #
  # @param [String, ManifestItem, Array, ActiveRecord::Relation] items
  # @param [Symbol]                 step
  # @param [Float, nil]             start_time
  # @param [Proc, nil]              callback
  # @param [Boolean]                fatal
  # @param [Hash]                   opt
  #
  # @option opt [String]            :manifest_id
  # @option opt [String]            :job_id
  # @option opt [SimulationOptions] :sim_opt
  # @option opt [Symbol]            :meth         If opt[:sim_opt]
  # @option opt [String]            :msg          If opt[:sim_opt]
  # @option opt [String]            :err          If opt[:sim_opt]
  #
  # @return [StepResult]
  #
  #--
  # noinspection RubyScope
  #++
  def submission_step(
    items,
    step:,
    start_time: nil,
    callback:   nil,
    fatal:      true,
    **opt
  )
    result = nil
    meth   = opt.delete(:meth) || __method__
    recs   = manifest_items(items)
    start_time ||= timestamp

    sim = (opt[:sim_opt] if opt[:simulation] && SIMULATION_ALLOWED)
    tag = sim && "*** SUBMIT --- #{self_class}.#{meth}"
    sim&.simulate_work(recs, tag, time: start_time, step: step, **opt)

    case step
      when :cache   then result = await_upload(recs, **opt)
      when :promote then result = promote_file(recs, **opt)
      when :index   then result = add_to_index(recs, **opt)
      when :entry   then result = create_entry(recs, **opt)
      else               raise %Q("#{step}" step: no submission method)
    end

  rescue => error
    # NOTE: *success* is assumed to be *nil* in this case.
    notice = error.to_s
    result = recs.map { |rec| [manifest_item_id(rec), notice] }.to_h
    raise error if fatal

  ensure
    if result.is_a?(StepResult)
      # === Result of any submission step except the final one.
      result.failure.transform_values! { |v| v.is_a?(Hash) ? v : { error: v } }
      result.success.transform_values! { |v| v.is_a?(Hash) ? v : {} }
    else
      # === Result of the final submission step or a rescued exception.
      result.transform_values! { |v| v.is_a?(Hash) ? v : { error: v } }
      failure = result.select { |_, v| v[:error] }
      success = result.except(*failure.keys)
      result  = StepResult.new(success: success, failure: failure)
    end
    if callback
      message = opt.slice(:simulation, :manifest_id, :job_id)
      message[:step]       = step
      message[:data]       = result.deep_dup.finalize.compact
      message[:start_time] = t_start = start_time
      message[:end_time]   = t_end   = timestamp
      message[:duration]   = duration(t_end, t_start, precision: 4)
      callback.(message)
    end
    return result
  end

  # ===========================================================================
  # :section: AWS steps
  # ===========================================================================

  protected

  # Return when the records contain Shrine metadata indicating their associated
  # files have been uploaded to cache.
  #
  # Conceptually the item is (or will enter) the :upload step on the client
  # side, which represents the actual upload to AWS cache.  The :cache step
  # obtains on the server side once the upload has caused the :file_data column
  # of the ManifestItem record to be updated.
  #
  # @param [Array<ManifestItem>] records
  # @param [Integer, Float]      wait
  # @param [Hash]                opt      @see #run_step
  #
  # @return [StepResult]
  #
  def await_upload(records, wait: 1, **opt)
    $stderr.puts "=== STEP #{__method__} | #{Emma::ThreadMethods.thread_name} | #{records.size} recs = #{records.map { |r| manifest_item_id(r) }} = #{records.inspect.truncate(1024)}" # TODO: testing - remove
    opt[:meth]    = __method__
    opt[:success] = config_text(:submission, :service, :uploaded)
    run_step(records, wait: wait, **opt) do |_id, rec|
      rec.file_uploaded_now?
    end
  end

  # Move the associated files into permanent storage.
  #
  # @param [Array<ManifestItem>] records
  # @param [Hash]                opt      @see #run_step
  #
  # @return [StepResult]
  #
  def promote_file(records, **opt)
    $stderr.puts "=== STEP #{__method__} | #{Emma::ThreadMethods.thread_name} | #{records.size} recs = #{records.map { |r| manifest_item_id(r) }} = #{records.inspect.truncate(1024)}" # TODO: testing - remove
    opt[:meth]    = __method__
    opt[:success] = config_text(:submission, :service, :stored)
    run_step(records, **opt) do |_id, rec|
      rec.promote_file(fatal: true)
    end
  end

  # ===========================================================================
  # :section: Indexing step
  # ===========================================================================

  protected

  # Add entries to the index.
  #
  # @param [Array<ManifestItem>] records
  # @param [Hash]                opt      @see #run_step
  #
  # @return [StepResult]
  #
  # === Usage Notes
  # This is the step where the submission ID associated with the ManifestItem
  # instance is generated/regenerated.
  #
  def add_to_index(records, **opt)
    fields = records.map(&:emma_metadata)
    $stderr.puts "=== STEP #{__method__} | #{Emma::ThreadMethods.thread_name} | #{records.size} recs = #{records.map { |r| manifest_item_id(r) }} | #{fields.size} fields = #{fields.inspect.truncate(1024)}" # TODO: testing - remove
    result = ingest_api.put_records(*fields)
    remaining, failure = process_ingest_errors(result, *records)

    opt[:meth]    = __method__
    opt[:success] = config_text(:submission, :service, :indexed)
    opt[:initial] = { failure: failure }

    now = DateTime.now
    run_step(remaining, **opt) do |_id, rec|
      rec.update_columns(last_indexed: now)
    end
  end

  # Interpret error message(s) generated by the EMMA Unified Ingest service to
  # determine which item(s) failed.
  #
  # @param [Ingest::Message::Response] result
  # @param [Array<ManifestItem>]       records
  # @param [Hash]                      opt
  #
  # @return [Array<(Array<ManifestItem>,Hash)>]
  #
  # @see ExecReport#error_table
  #
  # === Implementation Notes
  # It's not clear whether there would ever be situations where there was a mix
  # of errors by index, errors by submission ID, and/or general errors, but
  # this method was written to be able to cope with the possibility.
  #
  def process_ingest_errors(result, *records, **opt)

    # If there were no errors then indicate that all items succeeded.
    errors = ExecReport[result].error_table(**opt)
    return records, {} if errors.blank?

    # Otherwise, all items will be assumed to have failed.
    errors = errors.dup
    failed = {}

    # Errors associated with the position of the item in the request.
    by_index = errors.select { |idx| idx.is_a?(Integer) && records[idx-1] }
    if by_index.present?
      errors.except!(*by_index.keys)
      by_index.transform_keys!   { |idx| manifest_item_id(records[idx-1]) }
      by_index.transform_values! { |msg| Array.wrap(msg) }
      failed.rmerge!(by_index)
    end

    # Errors associated with item submission ID.
    by_sid = errors.extract!(*records.map(&:submission_id))
    if by_sid.present?
      sid_id = records.map { |rec| [rec.submission_id, rec] }.to_h
      by_sid.transform_keys!   { |sid| manifest_item_id(sid_id[sid]) }
      by_sid.transform_values! { |msg| Array.wrap(msg) }
      failed.rmerge!(by_sid)
    end

    # Remaining (general) errors indicate that there was a problem with the
    # request and that all items have failed.
    if errors.present?
      general   = errors.values.compact_blank.presence
      general ||= [config_text(:submission, :service, :unknown)]
      general   = records.map { |rec| [manifest_item_id(rec), general] }.to_h
      failed.rmerge!(general)
    end

    return [], failed

  end

  # ===========================================================================
  # :section: EMMA entry step
  # ===========================================================================

  protected

  COLUMN_KEY_MAP = {
    id:             :upload_id,
    submission_id:  :submission_id,
  }.freeze
  ENTRY_COLUMNS = COLUMN_KEY_MAP.keys.freeze
  RESULT_KEYS   = COLUMN_KEY_MAP.values.freeze

  # Create an Upload record for the entries that have made it through all of
  # the steps through index ingest.
  #
  # @param [Array<ManifestItem>]   records
  # @param [User, String, Integer] user
  #
  # @return [Hash{String=>Hash}]
  #
  def create_entry(records, user:, **)
    # Create matching EMMA entries from the values extracted/derived from each
    # item record.
    user    = user_id(user) unless user.is_a?(Integer)
    sid_rec = records.map { |rec| [rec.submission_id, rec] }.to_h
    fields  = records.map { |rec| entry_fields(rec, user: user) }
    $stderr.puts "=== STEP #{__method__} | #{Emma::ThreadMethods.thread_name} | #{records.size} recs = #{records.map { |r| manifest_item_id(r) }} | #{fields.size} fields = #{fields.inspect.truncate(1024)}" # TODO: testing - remove
    rows    = Upload.insert_all(fields, returning: ENTRY_COLUMNS).rows

    # Add successful submissions to the method result, and update and persist
    # the new values to the item record.
    result  = {}
    submit  = DateTime.now
    rows.each do |row|
      begin
        rec = nil
        col = RESULT_KEYS.zip(row).to_h
        sid = col[:submission_id] or raise "no sid in returned #{row.inspect}"
        rec = sid_rec.delete(sid) or raise "sid #{sid.inspect} unexpected"
        rec.update_columns(last_submit: submit)
        result[rec.id] = col
      rescue => error
        result[rec.id] = error.message if rec
        Log.warn { "#{__method__}: #{error.message}" }
      end
    end

    # Note any items that were not confirmed as having created a matching EMMA
    # entry record.
    if sid_rec.present?
      error  = config_text(:submission, :service, :db_error)
      error  = "#{__method__}: #{error}"
      failed = sid_rec.values.map { |rec| [rec.id, { error: error }] }.to_h
      result.merge!(failed)
    end

    result.stringify_keys!

  rescue => error
    notice = error.to_s
    Log.warn { "#{__method__}: #{notice}" }
    records.map { |rec| [rec.id.to_s, { error: notice }] }.to_h
  end

  # Required if the target records are in the 'uploads' table because that
  # schema does not use 'json' fields.
  #
  # @type [Boolean]
  #
  JSON_SERIALIZE = true

  # Generate a row of fields for #insert_all.
  #
  # If *sid* is a string, this has the side-effect of setting rec.submission_id
  # (without persisting)
  #
  # @param [ManifestItem]          rec
  # @param [User, String, Integer] user
  # @param [Boolean]               serialize  If *true*, serialize Hash values.
  #
  # @return [Hash]
  #
  def entry_fields(rec, user:, serialize: JSON_SERIALIZE)
    user = user_id(user) unless user.is_a?(Integer)
    ed   = rec.emma_metadata(refresh: true)
    fd   = rec.file_data
    mime = fd&.deep_symbolize_keys&.dig(:metadata, :mime_type)
    fmt  = mime_to_fmt(mime)
    ext  = fmt_to_ext(fmt)
    {
      user_id:        user,
      repository:     ed[:emma_repository],
      submission_id:  ed[:emma_repositoryRecordId],
      fmt:            ed[:dc_format] || FileFormat.metadata_fmt(fmt),
      ext:            ext,
      state:          'completed',
      phase:          'create',
      file_data:      (serialize ? fd.to_json : fd),
      emma_data:      (serialize ? ed.to_json : ed),
    }
  end

  # Return the indicated user record ID.
  #
  # @param [any, nil] user            User, String, Integer
  #
  # @return [Integer, nil]
  #
  def user_id(user)
    # noinspection RubyMismatchedReturnType
    user.is_a?(Integer) ? user : User.id_value(user)&.to_i
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  DEF_MSG = {
    success: 'succeeded',
    failure: '%{meth} failed',
    timeout: 'timed out',
  }

  # Perform a submission step on the given record(s) accumulating successes and
  # failures.
  #
  # If *wait* is given, the block is assumed to test a record condition which
  # will be changed externally; items that do not return *true* will be checked
  # again after the next wait.
  #
  # @param [Array<ManifestItem>] records
  # @param [Float, Integer, nil] wait
  # @param [Hash]                opt
  #
  # @option opt [String] :success   Default entry value for a succeeded item.
  # @option opt [String] :failure   Default entry value for a failed item.
  # @option opt [String] :timeout   Default entry value for a timed-out item.
  # @option opt [Float]  :max_time  Maximum run time per item.
  # @option opt [Hash]   :initial   Initial :success and/or :failure hashes.
  #
  # @return [StepResult]
  #
  # @yield [id, rec] Apply step-specific logic to the given record.
  # @yieldparam  [String]       id    The hash key for the record.
  # @yieldparam  [ManifestItem] rec   The record itself.
  # @yieldreturn [any, nil]           False or *nil* to indicate failure.
  #
  def run_step(records, wait: nil, **opt, &blk)

    max_time  = (opt[:max_time] || DEFAULT_TIMEOUT) * records.size
    max_time += records.map { |r| r.file_size.to_i / 1.megabyte }.sum if wait
    deadline  = timestamp + max_time

    meth      = opt[:meth] || __method__
    msg       = opt.slice(*DEF_MSG.keys).reverse_merge!(DEF_MSG)
    msg.transform_values! { |v| interpolate(v, meth: meth) }

    records   = records.map { |rec| [manifest_item_id(rec), rec] }.to_h
    remaining = records.dup
    failure   = opt.dig(:initial, :failure) || {}
    success   = opt.dig(:initial, :success) || records

    if wait
      # noinspection RubyMismatchedArgumentType
      while remaining.present? && sleep(wait)
        done = []
        remaining.each_pair do |id, rec|
          begin
            id = nil unless blk.call(id, rec)
          rescue => error
            failure[id] = error.message
            Log.warn { "#{meth}: #{error.message}" }
          end
          done << id if id
          break if timestamp > deadline
        end
        remaining.except!(*done)
      end
    else
      done = []
      remaining.each_pair do |id, rec|
        begin
          failure[id] = msg[:failure] unless blk.call(id, rec)
        rescue => error
          failure[id] = error.message
          Log.warn { "#{meth}: #{error.message}" }
        end
        done << id
        break if timestamp > deadline
      end
      remaining.except!(*done)
    end

    failure.merge!(remaining.transform_values { msg[:timeout] })
    success.except!(*failure.keys).transform_values! { msg[:success] }
    StepResult.new(success: success, failure: failure)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  class StepResult < ::Hash

    include Emma::Common

    TEMPLATE = {
      count:     0,
      invalid:   nil,
      submitted: nil,
      success:   nil,
      failure:   nil,
    }.freeze

    def initialize(arg = nil, **opt)
      replace(TEMPLATE)
      valid = opt.delete(:valid)
      opt[:submitted] ||= valid unless valid.nil?
      opt = arg.merge(opt)    if arg.present? && arg.is_a?(Hash)
      update(normalize!(opt)) if opt.present?
    end

    def count     = self[:count] || 0
    def valid     = submitted
    def invalid   = self[:invalid] || []
    def submitted = self[:submitted] || []
    def success   = self[:success] || {}
    def failure   = self[:failure] || {}

    def finalize(**opt)
      normalize!(opt).each_pair do |key, val|
        case
          when key == :count          then self[key] = val
          when self[key].is_a?(Hash)  then self[key].rmerge!(val)
          else                             self[key] = [*self[key], *val]
        end
      end
      self[:submitted] ||= [*ids(self[:success]), *ids(self[:failure])]
      self[:count]     ||= [*self[:submitted], *self[:invalid]].size
      each_pair do |key, val|
        next if val.nil?
        case val
          when Array
            case val.first
              when nil  then next
              when Hash then val = val.sort_by { |v| v.keys.first.to_s }
              else           val = val.sort_by(&:to_s).uniq
            end
          when Hash
            val = val.sort_by { |k, _| k.to_s }.to_h
          else
            val = Array.wrap(val) unless key == :count
        end
        self[key] = val
      end
    end

    protected

    def ids(arg) = arg.is_a?(Hash) ? arg.keys : Array.wrap(arg)

    def normalize!(opt)
      opt.slice!(*TEMPLATE.keys)
      opt.compact!
      opt.each_pair do |k, v|
        case
          when k == :count   then opt[k] = non_negative(v)
          when v.is_a?(Hash) then opt[k] = v.deep_dup
          else                    opt[k] = Array.wrap(v).deep_dup
        end
      end
    end

  end

  class SimulationOptions < ::Hash

    include SubmissionService::Action::Submit
    include Emma::ThreadMethods
    include Emma::TimeMethods

    #STEP_FAILURE_PROBABILITY = 7.5 / 100.0
    STEP_FAILURE_PROBABILITY = 15 / 100.0

    def initialize(**opt)
      super
      self[:tid] ||= thread_name
    end

    def tid
      self[__method__]
    end

    def value
      self[__method__] ||= rand * scale
    end

    def scale
      self[__method__] ||= 100.0
    end

    def percentile
      self[__method__] ||= scale * STEP_FAILURE_PROBABILITY
    end

    def index(i = nil)
      self[__method__] = i if i
      self[__method__]
    end

    def min_max
      # noinspection RubyMismatchedArgumentType
      min = index ? (percentile * index) : ((scale - percentile) / 2)
      min...(min + percentile)
    end

    def slice_delay
      self[__method__] ||= 0.1..0.3
    end

    def item_delay
      self[__method__] ||= 0.1..0.3
    end

    def work
      self[__method__] ||= 0.05..0.15
    end

    # Called to prepare simulation values for a new set of items.
    #
    def new_slice
      pause(slice_delay) if slice_delay
      self[:index] = nil
      self[:value] = nil
    end

    # Called to prepare simulation values for a new item.
    #
    def new_item
      pause(item_delay) if item_delay
      self[:index] = nil
      self[:value] = nil
    end

    # Called prior to performing a new submission step on one or more items.
    #
    # @return [Integer]
    #
    def new_step
      # noinspection RubyMismatchedReturnType
      index(index&.succ || 0)
    end

    # Called to simulate work.
    #
    # @param [String, ManifestItem, Array] item
    # @param [String, Array<String>]       tag
    # @param [Float, nil]                  time
    # @param [Symbol, nil]                 step
    # @param [String, nil]                 msg
    # @param [String, nil]                 err
    #
    def simulate_work(item, tag, time: nil, step: nil, msg: nil, err: nil, **)
      entry = step && SUBMIT_STEPS_TABLE[step] || {}
      raise "invalid step #{step.inspect}" if step && entry.blank?
      msg ||= entry[:msg] || entry[:sim_msg]
      err ||= entry[:err] || entry[:sim_err]
      msg &&= "TODO: #{msg}"
      err &&= ("SIMULATED #{err} FAILURE".upcase if min_max.include?(value))
      item  = Array.wrap(item).map { |v| manifest_item_id(v) }
      line  = Array.wrap(tag).tap { |parts|
        parts << "step = #{step}" if step
        parts << "tid = #{tid}"
        parts << item.join(', ')
        parts << "t = #{time || timestamp}"
        parts << (err || msg)
      }.join(' | ')
      $stderr.puts line
      # noinspection RubyMismatchedArgumentType
      raise err              if err
      pause(work, item.size) if work
    end

    # Sleep for a fixed time or randomly within a range of times.
    #
    # @param [Float,Range<Float>] time
    # @param [Numeric, nil]       factor
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    def pause(time, factor = nil)
      if factor && (factor != 1)
        if time.is_a?(Range)
          min  = time.first * factor
          max  = time.last  * factor
          time = Range.new(min, max, time.exclude_end?)
        else
          time = time * factor
        end
      end
      sleep(time.is_a?(Range) ? rand(time) : time)
    end

  end

end

__loading_end(__FILE__)

# app/services/lookup_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Encapsulates bibliographic metadata lookup.
#
# == Implementation Note
# Unlike other top-level classes in this directory, this is not a subclass of
# ApiService -- instead, the classes defined within its namespace are.
#
class LookupService

  include Emma::Time

  include Lookup

  # Include remote service modules from "app/services/lookup_service/**.rb".
  include_submodules(self)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Numeric]
  DEFAULT_TIMEOUT = 2 * RemoteService::DEFAULT_TIMEOUT

  # A table of defined external services and the bibliographic types they can
  # handle.  The entries are in descending order of preference.
  #
  # @type [Hash{Class=>Array<Symbol>}]
  #
  # @see LookupService::RemoteService::Properties#priority
  #
  SERVICE_TABLE =
    RemoteService.subclasses.select(&:enabled?).sort_by(&:name).map { |service|
      [service, service.types]
    }.sort_by { |service, types|
      [service.priority, -(types.size), service.name]
    }.to_h.deep_freeze

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  ADD_DIAGNOSTICS = true

  # Get bibliographic information about the given items.
  #
  # @param [LookupService::Request] request
  # @param [LookupChannel, nil]     channel
  # @param [Numeric, Boolean, nil]  timeout   Default: `#DEFAULT_TIMEOUT`.
  #
  # @return [nil, Hash{String=>LookupService::Response}]
  #
  #--
  # == Variations
  #++
  #
  # @overload request(items, channel:, timeout: nil)
  #   Access remote services asynchronously.
  #   @param [LookupService::Request] request
  #   @param [LookupChannel]          channel
  #   @param [Numeric, Boolean, nil]  timeout   Default: `#DEFAULT_TIMEOUT`.
  #   @return [nil]
  #
  # @overload request(items, timeout: nil)
  #   Access remote services one at a time.
  #   @param [LookupService::Request] request
  #   @param [Numeric, Boolean, nil]  timeout   Default: `#DEFAULT_TIMEOUT`.
  #   @return [Hash{String=>LookupService::Response}]
  #
  def self.request(request, channel: nil, timeout: nil)
    __debug_job(__method__) { { channel: channel, timeout: timeout } }
    case timeout
      when false   then timeout = nil
      when Numeric then timeout = DEFAULT_TIMEOUT unless timeout&.positive?
      else              timeout = DEFAULT_TIMEOUT
    end
    if channel
      # noinspection RubyNilAnalysis
      get_async(request, timeout: timeout, stream_name: channel.stream_name)
    else
      # noinspection RubyMismatchedArgumentType
      get_sync(request, timeout: timeout)
    end
  end

  # Synchronously get bibliographic information via the given service.
  #
  # @param [Class, LookupService::RemoteService] service
  # @param [LookupService::Request]              request
  # @param [Hash]                                opt
  #
  # @return [LookupService::Response]
  #
  # @see LookupJob#worker_task
  # @see LookupService#get_sync
  #
  def self.get_from(service, request, **opt)
    opt[:extended] = true if ADD_DIAGNOSTICS && !opt.key?(:extended)
    service = service.new if service.is_a?(Class)
    service.lookup_metadata(request, **opt)
  end

  # services_for
  #
  # @param [LookupService::Request, Hash, Array, String] items
  # @param [String, Boolean, nil]                        log
  #
  # @return [Array<Class>]
  #
  def self.services_for(items, log: nil)
    log   = log.is_a?(TrueClass) ? __method__ : log.presence
    types = LookupService::Request.wrap(items).id_types.presence
    SERVICE_TABLE.select { |service, service_types|
      service.enabled? && (types.nil? || types.intersect?(service_types)) or
        (Log.debug { "#{log}: #{service}: skipped" } if log)
    }.keys
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Access remote services asynchronously.
  #
  # @param [LookupService::Request] request
  # @param [Hash]                   opt       Passed to LookupJob#perform
  #
  # @option opt [Numeric, nil] :timeout
  #
  # @return [nil]
  #
  def self.get_async(request, **opt)
    log      = "#{name}.#{__method__}"
    services = services_for(request, log: log)
    LookupJob.perform_later(services, request, opt) and nil
  end

  # Access remote services one at a time.
  #
  # @param [LookupService::Request] request
  # @param [Numeric, nil]           timeout
  # @param [Hash]                   opt       Passed to #get_from.
  #
  # @return [Hash{String=>LookupService::Response}]
  #
  def self.get_sync(request, timeout: nil, **opt)
    # noinspection RubyMismatchedArgumentType
    deadline = (timestamp + timeout if timeout)
    log      = "#{name}.#{__method__}"
    services = services_for(request, log: log)
    services.map { |service|
      # noinspection RubyMismatchedReturnType
      if deadline && (timestamp > deadline)
        Log.warn { "#{log}: #{service}: timed out" }
      else
        [service.name, get_from(service, request, **opt)]
      end
    }.compact.to_h
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Combine the data from multiple threads.
  #
  # Each top level *table* entry is a hash returned by #post_fight.
  #
  # @param [Hash{*=>Hash}]                              table
  # @param [LookupService::Request, Array<String>, nil] request
  #
  # @return [Hash]
  #
  # @see LookupService::RemoteService#post_fight
  #
  def self.merge_data(table, request = nil)
    # @type [Array<PublicationIdentifier>]
    all_ids = []
    # @type [Array<Hash>]
    entries =
      table.map { |_thread_id, thread_result|
        thread_result&.dig(:data, :items)&.values
      }.flatten.map! { |entry|
        next if (ids = entry&.dig(:dc_identifier)).blank?
        ids = [ids] unless (ok_as_is = ids.is_a?(Array))
        all_ids += ids
        ok_as_is ? entry : entry.merge(dc_identifier: ids)
      }
    request &&= LookupService::Request.wrap(request)
    matching_ids =
      request&.identifiers&.map(&:to_s)&.presence ||
      all_ids.map(&:to_s).group_by(&:itself).keep_if { |_,ids| ids.many? }.keys
    result =
      if matching_ids.present?
        entries.compact!
        entries.select! { |e| e[:dc_identifier].intersect?(matching_ids) }
        blend_data(*entries) if entries.present?
      end
    { blend: (result || {}) }
  end

  # Combine the data from multiple entries.
  #
  # Each top level *table* entry is a hash returned by #post_fight.
  #
  # @param [Array<Hash{Symbol=>*}>] entries
  #
  # @return [Hash{Symbol=>*}]
  #
  def self.blend_data(*entries)
    LookupService::Data::Item::FIELDS.map { |field|
      next if (values = entries.flat_map { |e| e[field] }.compact).blank?
      values = fix_names(values) if field == :dc_creator
      [field, eliminate_substrings(values)]
    }.compact.to_h.tap do |result|
      normalize_dates!(result)
      result[:dc_subject]&.sort_by! { |v| [v, v.size] }
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # @private
  FAMILY_NAME_GIVEN_NAME_DATES =
    /^([^,]+),\s*(.*?)[\s,;]+(\[.*\]|\(.*\)|\d+.*\d+|\d+-?)$/.freeze

  # @private
  FAMILY_NAME_GIVEN_NAME =
    /^([^,]+),\s*(.*)$/.freeze

  # Put proper names in a consistent order.
  #
  # @param [Array<String>] values
  #
  # @return [Array<String>]
  #
  def self.fix_names(values)
    values.map do |name|
      case name
        when FAMILY_NAME_GIVEN_NAME_DATES then "#{$2} #{$1}, #{$3}"
        when FAMILY_NAME_GIVEN_NAME       then "#{$2} #{$1}"
        else                                   name
      end
    end
  end

  # Convert values to strings and eliminate individual values which are
  # duplicates or substrings of other values (based on a comparison of
  # normalized values so that differences in punctuation or capitalization are
  # disregarded).
  #
  # @param [Array] values
  #
  # @return [Array<String>]
  #
  def self.eliminate_substrings(values)
    value_map = values.map.with_index { |value, key| [key, value] }.to_h
    normalized_map =
      value_map.transform_values { |value|
        Api::Shared::CommonMethods.normalized(value)
      }.sort_by { |_, value| -value.size }.to_h
    normalized_map.each_with_index do |(_key, value), index|
      normalized_map.each_with_index do |(k, v), i|
        value_map[k] = nil if (i > index) && value.include?(v)
      end
    end
    value_map.values.compact
  end

  # Transform "YYYY-01-01" values for :emma_publicationDate into "YYYY" values
  # for :dcterms_dateCopyright.  Eliminate :dcterms_dateCopyright values which
  # are already indicated by the remaining "YYYY-MM-DD" :emma_publicationDate
  # values.
  #
  # @param [Hash] result
  #
  # @return [Hash]                    The *result* hash, possibly modified.
  #
  def self.normalize_dates!(result)
    pub_dates  = Array.wrap(result[:emma_publicationDate])
    pub_years, pub_days = pub_dates.partition { |d| d.end_with?('-01-01') }
    cpr_years  = Array.wrap(result[:dcterms_dateCopyright])
    cpr_years += pub_years.map { |d| d.first(4) }
    cpr_years -= pub_days.map { |d| d.first(4) }
    cpr_years.uniq!
    case cpr_years.size
      when 0 then result.delete(:dcterms_dateCopyright)
      when 1 then result[:dcterms_dateCopyright] = cpr_years.first
      else        result[:dcterms_dateCopyright] = cpr_years.sort
    end
    case pub_days.size
      when 0 then result.delete(:emma_publicationDate)
      when 1 then result[:emma_publicationDate] = pub_days.first
      else        result[:emma_publicationDate] = pub_days.sort
    end
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  if DEBUG_CABLE && false

    # @type [Hash{Symbol=>String,Regexp}]
    PATTERN = {
      all:      /\.good_job$/,
      enqueue:  'enqueue_job.good_job',
      perform:  'perform_job.good_job',
      finished: 'finished_job_task.good_job'
    }.deep_freeze

    def self.pattern(name = nil)
      case name
        when Array  then Regexp.new(name.join('|'))
        when Regexp then name
        when String then name.include?('.') ? name : "#{name}.good_job"
        when Symbol then PATTERN[name]
        else             PATTERN[:all]
      end
    end

    ActiveSupport::Notifications.subscribe(pattern) do |*args|
      name, start, finished, unique_id, data = args
      big_data = %i[scheduler active_job good_job execution result]
      line = {
        name:        name,
        unique_id:   unique_id,
        start:       start,
        finished:    finished,
        'data.keys': data.keys,
        data:        data.except(*big_data),
      }.merge!(data.slice(*big_data))
      $stderr.puts
      line.each do |k, v|
        $stderr.puts '@@@ INSTRUMENTATION %-10s = %s' % [k, v.inspect]
      end
      $stderr.puts
    end

  end

end

__loading_end(__FILE__)

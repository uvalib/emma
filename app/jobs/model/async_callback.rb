# app/jobs/model/async_callback.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# @note This class may go away...
class Model::AsyncCallback

  include Emma::Debug
  extend  Emma::Debug

  # @private
  CLASS = self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [ApplicationRecord<Record::Steppable>]
  attr_reader :receiver

  # @return [Symbol]
  attr_reader :meth

  # @return [Model::AsyncCallback, nil]
  attr_reader :callback

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # initialize
  #
  # @param [ApplicationRecord, Hash, AsyncCallback, nil] src
  # @param [Symbol, nil]                                 meth
  # @param [AsyncCallback, nil]                          callback
  # @param [Hash]                                        opt
  #
  #--
  # === Variations
  #++
  #
  # @overload initialize(src)
  #   @param [AsyncCallback] src
  #
  # @overload initialize(src)
  #   @param [Hash] src
  #   @option src [ApplicationRecord]   :cb_receiver   Required.
  #   @option src [Symbol]              :cb_method     Required.
  #   @option src [Hash, AsyncCallback] :callback      Optional.
  #
  # @overload initialize(receiver, meth, callback)
  #   @param [ApplicationRecord] receiver
  #   @param [Symbol]            meth
  #   @param [AsyncCallback]     callback
  #
  # @overload initialize(receiver, meth, **opt)
  #   @param [ApplicationRecord] receiver
  #   @param [Symbol]            meth
  #   @param [Hash]              opt                  In place of *callback*
  #   @option opt [ApplicationRecord]  :cb_receiver   Required.
  #   @option opt [Symbol]             :cb_method     Required.
  #
  # @overload initialize(**opt)
  #   @param [Hash] opt                               In place of *callback*
  #   @option opt [ApplicationRecord]  :cb_receiver   Required.
  #   @option opt [Symbol]             :cb_method     Required.
  #
  #--
  # noinspection RubyMismatchedVariableType
  #++
  def initialize(src = nil, meth = nil, callback = nil, **opt)
    __debug_items(binding)
    if src.is_a?(CLASS) || src.is_a?(Hash)
      receiver, meth, callback = CLASS.cb_values(src)
    elsif opt.present?
      receiver, meth, callback = CLASS.cb_values(opt)
    else
      receiver = src
    end
    __output "#{CLASS} FAIL\n#{caller.pretty_inspect}" unless receiver && meth # TODO: remove - testing
    @receiver = receiver or raise "#{CLASS}: no receiver"
    @meth     = meth     or raise "#{CLASS}: no method"
    @callback = callback && CLASS[callback]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Enqueue or run the callback as a job.
  #
  # @param [Boolean] async            Run synchronously if provided as *false*.
  # @param [Hash]    opt
  #
  # @return [Boolean]                 *false* if the job could not be processed
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def cb_schedule(async: true, **opt)
    async = false # TODO: remove when implementing async jobs
    opt[:callback] = callback if callback.present?
    async ? cb_perform_later(**opt) : cb_perform_now(**opt)
  end

  # Run the callback as a synchronous job.
  #
  # @param [Hash] opt
  #
  # @return [Boolean]                 Always *true* # TODO: ???
  #
  def cb_perform_now(**opt)
    __debug { "#{__method__} | opt = #{opt.inspect}" } # TODO: remove
    receiver.job_class.perform_now(receiver, meth, **opt)
    true # TODO: return from #perform ???
  end

  # Queue a job to run the callback asynchronously.
  #
  # @param [Hash] opt
  #
  # @return [Boolean]                 *true* if queued; *false* if not.
  #
  def cb_perform_later(**opt)
    __debug { "#{__method__} | opt = #{opt.inspect}" } # TODO: remove
    receiver.job_class.perform_later(receiver, meth, **opt).present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def to_h
    { cb_receiver: receiver, cb_method: meth, callback: callback }
  end

  alias_method :to_hash, :to_h

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def self.cb_values(source, *)
    return unless source.respond_to?(:to_h)
    source.to_h.values_at(:cb_receiver, :cb_method, :callback)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  class Serializer < ActiveJob::Serializers::ObjectSerializer

    def serialize(item)
      super(item.to_h)
    end

    def deserialize(hash)
      fields = hash.map { [_1.to_sym, deserialize(_2)] }.to_h
      klass.new(**fields)
    end

    private

    def klass
      CLASS
    end

    # noinspection RubyResolve
    Rails.configuration.active_job.custom_serializers << self

  end

end


__loading_end(__FILE__)

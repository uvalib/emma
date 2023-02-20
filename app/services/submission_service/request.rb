# app/services/submission_service/request.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SubmissionService::Request
#
# @note This is an abstract base class.
#
# == Implementation Notes
# This class can't be implemented as a subclass of Hash because the ActiveJob
# serializer will fail to distinguish it from a simple Hash (and thereby fail
# to engage its custom serializer/deserializer).
#
class SubmissionService::Request

  include SubmissionService::Common

  include Serializable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DEFAULT_COMMAND = :start

  # The format of a request object.
  #
  # @type [Hash]
  #
  TEMPLATE = {
    simulation:   nil,
    manifest_id:  nil,
    items:        [],
  }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [Hash]
  attr_reader :table

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create a new instance.
  #
  # @param [SubmissionService::Request, Hash, Array, String, nil] arg
  # @param [Hash]                                                 opt
  #
  def initialize(arg = nil, **opt)
    opt_args = extract_hash!(opt.compact_blank!, *template.keys)
    arg    ||= opt_args
    m_id     = opt_args[:manifest_id] ||= extract_manifest_id(arg, **opt)
    opt_args[:items] ||= extract_items(arg, **opt, manifest_id: m_id)
    # noinspection RubyMismatchedArgumentType
    @table = template.merge(opt_args)
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  def dup
    self.class.new(self)
  end

  def deep_dup
    self.class.new(self)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this request is part of a simulation.
  #
  def simulation?
    table[:simulation].present?
  end

  # command
  #
  # @return [Symbol]
  #
  def command
    DEFAULT_COMMAND
  end

  # manifest_id
  #
  # @return [String]
  #
  def manifest_id
    table[:manifest_id]
  end

  # items
  #
  # @return [Array<String>]
  #
  def items
    table[:items]
  end

  # Present the entire request structure as a Hash.
  #
  # @return [Hash]
  #
  def to_h
    table.compact
  end

  delegate_missing_to :table

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new instance from *item* if it is not already an instance.
  #
  # @param [SubmissionService::Request, *] item
  #
  # @return [SubmissionService::Request]
  #
  def self.wrap(item)
    item.is_a?(self) ? item : new(item)
  end

  def self.batch?(*)         = false
  def self.request_method(*) = nil
  def self.response_class(*) = SubmissionService::Response
  def self.template(*)       = TEMPLATE

  delegate :batch?, :request_method, :response_class, :template, to: :class

  # ===========================================================================
  # :section: SubmissionService::Request::Serializer
  # ===========================================================================

  protected

  # Create a serializer for this class and any subclasses derived from it.
  #
  # @param [Class] this_class
  #
  # @see Serializer::Base#serialize?
  #
  def self.make_serializers(this_class)
    this_class.class_exec do

      serializer :serialize do |instance|
        instance.to_h
      end

      serializer :deserialize do |hash|
        new(re_symbolize_keys(hash))
      end

      def self.inherited(subclass)
        make_serializers(subclass)
      end

    end
  end

  make_serializers(self)

end

# SubmissionService::SubmitRequest
#
# @see file:javascripts/shared/submit-request.js *SubmitRequest*
#
class SubmissionService::SubmitRequest < SubmissionService::Request

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [SubmissionService::Request, Hash, Array, String, Symbol, nil] arg
  # @param [Hash]                                                         opt
  #
  def initialize(arg = nil, **opt)
    opt[:scope] ||= :submittable
    super
  end

  # ===========================================================================
  # :section: SubmissionService::Request overrides
  # ===========================================================================

  public

  def self.request_method = :batch_create
  def self.response_class = SubmissionService::SubmitResponse

end

# SubmissionService::BatchSubmitRequest
#
# @see file:javascripts/shared/submit-request.js *SubmitRequest*
#
class SubmissionService::BatchSubmitRequest < SubmissionService::Request

  # ===========================================================================
  # :section: SubmissionService::Request overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [SubmissionService::Request, Hash, Array, String, nil] arg
  # @param [Hash]                                                 opt
  #
  def initialize(arg = nil, **opt)
    batch    = opt.delete(:batch)
    arg_hash = extract_hash!(opt.compact_blank!, *template.keys)
    arg    ||= arg_hash
    m_id     = arg_hash[:manifest_id] ||= extract_manifest_id(arg, **opt)
    items    = arg_hash[:items]       ||= extract_items(arg, **opt)
    opt[:batch] = batch if (batch = batch_size_for(batch, items))
    arg_hash[:items] = make_sub_requests(items, **opt, manifest_id: m_id)
    super(**arg_hash)
  end

  # items
  #
  # @return [Array<SubmissionService::SubmitRequest>]
  #
  def items
    # noinspection RubyMismatchedReturnType
    super
  end

  alias :requests :items

  # ===========================================================================
  # :section: SubmissionService::Request overrides
  # ===========================================================================

  public

  def self.batch?         = true
  def self.response_class = SubmissionService::BatchSubmitResponse

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create sub-requests for a set of manifest items.
  #
  # @param [SubmissionService::SubmitRequest, Array, nil] arg
  # @param [Hash]                                         opt
  #
  # @return [Array<SubmissionService::SubmitRequest>]
  #
  def self.make_sub_requests(arg = nil, **opt)
    arg   = arg.deep_symbolize_keys if arg.is_a?(Hash)
    arg   = opt = arg.merge!(opt)   if arg.is_a?(Hash)
    arg   = opt                     if arg.nil?
    arg   = arg[:items]             if arg.is_a?(Hash) && arg[:items]
    arg   = arg.items               if arg.respond_to?(:items)
    items = Array.wrap(arg)
    batch = batch_size_for(opt[:batch], items) || 1
    m_id  = opt[:manifest_id]
    items.each_slice(batch).map do |subset|
      SubmissionService::SubmitRequest.new(subset, manifest_id: m_id)
    end
  end

  delegate :make_sub_requests, to: :class

end

# SubmissionService::ControlRequest
#
# @see file:javascripts/shared/submit-request.js *SubmitControlRequest*
#
class SubmissionService::ControlRequest < SubmissionService::Request

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEMPLATE = {
    command: nil,
    job_id:  nil,
    **superclass::TEMPLATE,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [SubmissionService::Request, Hash, Array, String, Symbol, nil] items
  # @param [Hash]                                                         opt
  #
  def initialize(items = nil, **opt)
    command = opt.delete(:command)
    items, command = [nil, items] if items.is_a?(Symbol)
    opt[:command] = command&.to_sym || DEFAULT_COMMAND
    # noinspection RubyMismatchedArgumentType
    super(items, **opt)
  end

  # ===========================================================================
  # :section: SubmissionService::Request overrides
  # ===========================================================================

  public

  # command
  #
  # @return [Symbol]
  #
  def command
    table[:command]
  end

  # job_id
  #
  # @return [String,nil]
  #
  def job_id
    table[:job_id]
  end

  def request_method(switch = nil)
    case (switch ||= command)
      when :cancel then :batch_cancel
      when :pause  then :batch_pause
      when :resume then :batch_resume
      else              raise "#{__method__}: #{switch}: invalid"
    end
    .tap { |meth| raise "#{__method__}: #{switch}: #{meth}: not implemented" }
  end

  # ===========================================================================
  # :section: SubmissionService::Request overrides
  # ===========================================================================

  public

  def self.response_class = SubmissionService::ControlResponse
  def self.template       = TEMPLATE

end

__loading_end(__FILE__)

# app/services/submission_service/definition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Interface to the shared data structure which holds the definition of the API
# requests and parameters.
#
module SubmissionService::Definition

  include SubmissionService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Marshal data in preparation for the remote request.
  #
  # @param [SubmissionService::Request, Symbol, nil]           meth
  # @param [SubmissionService::Request, Manifest, String, nil] arg
  # @param [Array<String>, nil]                                items
  # @param [Hash]                                              opt
  #
  # @return [SubmissionService::Request]   The value for @request.
  #
  def pre_flight(meth, arg = nil, items = nil, **opt)
    meth, arg, items = [nil, meth, arg] unless meth.nil? || meth.is_a?(Symbol)
    command = meth && (meth != SubmissionService::Request::DEFAULT_COMMAND)
    request = arg.is_a?(SubmissionService::Request)
    limited = items.present?
    if command && !request
      items ||= arg
      SubmissionService::ControlRequest.new(items, command: meth)
    elsif arg.is_a?(SubmissionService::SubmitRequest) || !request
      items ||= request ? arg.items : Array.wrap(arg)
      if (opt[:batch] = batch_size_for(opt[:batch], items))
        SubmissionService::BatchSubmitRequest.new(items, **opt)
      elsif limited || !request
        SubmissionService::SubmitRequest.new(items)
      else
        arg
      end
    elsif limited
      items ||= arg.items
      arg.class.new(items, **opt)
    else
      arg
    end
  end

  # Extract results from the remote response.
  #
  # @param [any, nil] obj       SubmissionService::Response, SubmissionService::Request
  # @param [Boolean]  extended  If *true*, include :diagnostic.
  #
  # @return [SubmissionService::Response] The value for @result.
  #
  def post_flight(obj = nil, extended: false, **opt)
    case obj
      when SubmissionService::Response
        rsp = obj
      when SubmissionService::Request
        rsp = obj.response_class.new(obj, **opt)
      else
        obj = obj.is_a?(Hash) ? obj.compact : { data: obj } if obj
        rsp = self.request.response_class.new(obj, **opt)
    end
    t_start = rsp[:start_time] ||= obj[:start_time] || self.start_time
    t_end   = rsp[:end_time]   ||= self.end_time    || timestamp
    rsp[:duration]    ||= duration(t_end, t_start)
    rsp[:manifest_id] ||= opt[:manifest_id]
    rsp[:diagnostic]    = rsp.diagnostic if extended
    rsp[:error]         = rsp.error      if extended
    rsp
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.include(ApiService::Definition)
    base.extend(self)
  end

end

__loading_end(__FILE__)

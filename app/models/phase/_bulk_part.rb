# app/models/phase/_bulk_part.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for phases that are can be part of bulk operations.
#
class Phase::BulkPart < Phase

  include Record::Bulk::Part

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # set_callback!
  #
  # @param [Hash]        opt
  # @param [Symbol, nil] meth   If not given, built from `#calling_method`.
  #
  # @return [Hash]              The modified *opt* hash.
  #
  def set_callback!(opt, meth = nil)
    inner_cb = opt.delete(:callback)
    if inner_cb && !inner_cb.is_a?(Model::AsyncCallback)
      inner_cb = Model::AsyncCallback.new(inner_cb)
    end
    if (inner_opt = opt.slice(:cb_receiver, :cb_method)).present?
      if inner_cb
        Log.warn { "#{__method__}: ignored #{inner_opt.inspect}" }
      else
        inner_cb = Model::AsyncCallback.new(inner_opt)
      end
      opt.except!(*inner_opt.keys)
    end
    meth ||= calling_method&.sub(/!$/, '_cb')&.to_sym
    cb = Model::AsyncCallback.new(self, meth, inner_cb)
    opt.merge!(callback: cb)
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the status of the given Phase instance. # TODO: I18n
  #
  # @param [Phase] phase
  # @param [Hash]  opt
  #
  # @option opt [Integer] :bulk_id    Override bulk identity from *phase*.
  #
  # @return [String]
  #
  def self.describe_status(phase, **opt)
    # @type [Phase::BulkOperation] bulk
    # @type [Integer, nil]         group
    bulk  = phase.bulk
    group = opt[:bulk_id] || bulk&.id
    super.tap do |note|
      if group.present?
        count = Phase.where(bulk_id: group).count
        part  = 'part'
        part  = "one of #{count} #{part.pluralize(count)}" if count > 1
        note << " as #{part} of bulk operation ##{group}"
        note << ' - '
        note << bulk.describe_status
      end
    end
  end

end

__loading_end(__FILE__)

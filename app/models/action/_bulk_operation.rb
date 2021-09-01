# app/models/action/_bulk_operation.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for compound operations.
#
class Action::BulkOperation < Action

  include Record::Bulk::Operation

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  before_destroy do
    __debug_line("*** Action::BulkOperation #{type} ***")
    # TODO: If batches are associated with ActiveJobs, kill each one.
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Each entry is a reference to the items which are the focus of the batch
  # operation.
  #
  # @return [Array, nil]
  #
  attr_reader :targets

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash, ActionController::Parameters, Model, nil] attr
  # @param [Hash, nil]                                      opt
  # @param [Proc, nil]                                      block
  #
  # @option attr [Array] :targets     If *attr* is a Hash or Hash-like.
  # @option opt  [Array] :targets     If *opt* hash is provided.
  #
  def initialize(attr = nil, opt = nil, &block)
    data = (opt[:targets] if opt.is_a?(Hash))
    # noinspection RubyNilAnalysis
    if attr && !attr.is_a?(ApplicationRecord) && attr.key?(:targets)
      data ||= attr[:targets]
      attr = attr.except(:targets)
    end
    super(attr, &block)
    @targets = Array.wrap(data).compact_blank
    raise 'no :targets given for batch action' if @targets.empty?
  end

  # ===========================================================================
  # :section: Record::Describable
  # ===========================================================================

  interpolation_methods do

    def describe_targets(action = nil, **)
      action ||= self_for_instance_method(__method__)
      targets  = action.try(:targets).presence or return 'NONE'

      total = targets.size
      items = { id: [], sid: [], other: [] }
      targets.each do |target|
        if (sid = sid_value(target))
          items[:sid]   << sid
        elsif (id = id_value(target))
          items[:id]    << id
        else
          items[:other] << target.to_s
        end
      end

      items.map { |kind, array|
        next if (size = array.size).zero?
        part = []
        part << kind.to_s.pluralize(size) if size < total
        part << array.join(', ')
        part.join(' ')
      }.compact.join('; ')
    end

  end

end

__loading_end(__FILE__)

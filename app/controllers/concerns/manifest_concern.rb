# app/controllers/concerns/manifest_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/manifest" controller.
#
# @!method paginator
#   @return [Manifest::Paginator]
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module ManifestConcern

  extend ActiveSupport::Concern

  include Emma::Common

  include ParamsHelper
  include FlashHelper
  include HttpHelper

  include OptionsConcern
  include PaginationConcern
  include ResponseConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters associated with manifest identification.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = Manifest::Options::IDENTIFIER_PARAMS

  # URL parameters associated with POST data.
  #
  # @type [Array<Symbol>]
  #
  DATA_PARAMS = Manifest::Options::DATA_PARAMS

  # The manifest identified in URL parameters either as :selected or :id.
  #
  # @return [String, nil]
  #
  def identifier
    manifest_params unless defined?(@identifier)
    @identifier
  end

  # URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def manifest_params
    @manifest_params ||=
      request.get? ? get_manifest_params : manifest_post_params
  end

  # Get URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def get_manifest_params
    model_options.get_model_params.tap do |prm|
      prm[:user] = @user if @user && !prm[:user] && !prm[:user_id]
      @identifier ||= extract_identifier(prm)
    end
  end

  # Extract POST parameters that are usable for creating/updating a Manifest
  # instance.
  #
  # @return [Hash{Symbol=>*}]
  #
  def manifest_post_params
    model_options.model_post_params.tap do |prm|
      extract_hash!(prm, *DATA_PARAMS).each_pair do |_, v|
        next unless (v &&= safe_json_parse(v)).is_a?(Hash)
        next unless (id = positive(v[:id]))
        prm[:id] = id
      end
      @identifier ||= extract_identifier(prm)
    end
  end

  # manifest_request_params
  #
  # @param [Manifest, Hash{Symbol=>*}, *] manifest
  # @param [Hash{Symbol=>*}, nil]         prm
  #
  # @return [Array<(Manifest, Hash{Symbol=>*})>]
  # @return [Array<(Any, Hash{Symbol=>*})>]
  #
  def manifest_request_params(manifest, prm = nil)
    manifest, prm = [nil, manifest] if manifest.is_a?(Hash)
    prm ||= manifest_params
    return manifest, prm
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # extract_identifier
  #
  # @param [Hash] prm
  #
  # @return [String, nil]
  #
  def extract_identifier(prm)
    manifest_id, id, sel = prm.values_at(*IDENTIFIER_PARAMS).map(&:presence)
    sel || manifest_id || id
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Parameters used by Manifest#search_records.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_RECORDS_PARAMS = Manifest::SEARCH_RECORDS_OPTIONS

  # Manifest#search_records parameters that specify a distinct search query.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_ONLY_PARAMS = (SEARCH_RECORDS_PARAMS - %i[offset limit]).freeze

  # Parameters used by #find_by_match_records or passed on to
  # Manifest#search_records.
  #
  # @type [Array<Symbol>]
  #
  FIND_OR_MATCH_PARAMS = (
    SEARCH_RECORDS_PARAMS + %i[group user user_id]
  ).freeze

  # Locate and filter Manifest records.
  #
  # @param [Array<String,Array>] items  Default: `ManifestConcern#identifier`.
  # @param [Hash]                opt    Passed to Manifest#search_records;
  #                                       default: `#manifest_params` if no
  #                                       *items* are given.
  #
  # @raise [Record::SubmitError]        If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]
  #
  def find_or_match_manifests(*items, **opt)
    items = items.flatten.compact
    items << identifier if items.blank? && identifier.present?

    # If neither items nor field queries were given, use request parameters.
    if items.blank? && (opt[:groups] != :only)
      opt = manifest_params.merge(opt) if opt.except(*SEARCH_ONLY_PARAMS).blank?
    end
    opt[:limit] ||= paginator.page_size
    opt[:page]  ||= paginator.page_number

    # Disallow experimental database WHERE predicates unless privileged.
    opt.slice!(*FIND_OR_MATCH_PARAMS) unless current_user&.administrator?

    # Select records for the current user unless a different user has been
    # specified (or all records if specified as '*', 'all', or 'false').
    user = opt.delete(:user)
    user = opt.delete(:user_id) || user || @user
    user = user.to_s.strip.downcase if user.is_a?(String) || user.is_a?(Symbol)
    # noinspection RubyMismatchedArgumentType
    user = User.find_record(user)   unless %w(* 0 all false).include?(user)
    opt[:user_id] = user.id         if user.is_a?(User) && user.id.present?

    # Limit records to those in the given state (or records with an empty state
    # field if specified as 'nil', 'empty', or 'missing').
    # noinspection RubyUnusedLocalVariable
    if (state = opt.delete(:state).to_s.strip.downcase).present?
=begin
      if %w(empty false missing nil none null).include?(state)
        opt[:state] = nil
      else
        opt[:state] = state
        #opt[:edit_state] ||= state
      end
=end
    end

    # Limit by workflow status group.
    # noinspection RubyUnusedLocalVariable
    group = opt.delete(:group)
=begin
    group = group.split(/\s*,\s*/) if group.is_a?(String)
    group = Array.wrap(group).compact_blank
    if group.present?
      group.map!(&:downcase).map!(&:to_sym)
      if group.include?(:all)
        %i[state edit_state].each { |k| opt.delete(k) }
      else
        states =
          group.flat_map { |g|
            Record::Steppable::STATE_GROUP.dig(g, :states)
          }.compact.map(&:to_s)
        #%i[state edit_state].each do |k|
        %i[state].each do |k|
          opt[k] = (Array.wrap(opt[k]) + states).uniq
          opt.delete(k) if opt[k].empty?
        end
      end
    end
=end
    opt.delete(:groups)

    Manifest.search_records(*items, **opt)

  rescue RangeError => error

    # Re-cast as a SubmitError so that ManifestController#index redirects to
    # the main index page instead of the root page.
    raise Record::SubmitError.new(error)

  end

  # Return with the specified Manifest record.
  #
  # @param [String, Hash, Manifest, nil] item  Def `ManifestConcern#identifier`
  # @param [Hash]                        opt   Passed to Manifest#find_record.
  #
  # @raise [Record::StatementInvalid]   If :id not given.
  # @raise [Record::NotFound]           If *item* was not found.
  #
  # @return [Manifest, nil]
  #
  def get_manifest(item = nil, **opt)
    # noinspection RubyMismatchedReturnType
    Manifest.find_record((item || identifier), **opt)
  end

  # Locate related ManifestItem records.
  #
  # @param [Manifest, nil] item
  # @param [Hash]          opt
  #
  # @raise [Record::SubmitError]        If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]
  #
  def find_or_match_manifest_items(item = nil, **opt)
    # An :id is only valid in this context if it's a ManifestItem ID.
    opt[:id] &&= positive(opt[:id]) or opt.delete(:id)
    opt[:limit]       ||= paginator.page_size
    opt[:page]        ||= paginator.page_number
    opt[:manifest_id] ||= item&.id || identifier
    ManifestItem.search_records(**opt)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # Start a new (un-persisted) manifest.
  #
  # @param [Hash, nil] opt            Default: `#get_manifest_params`.
  #
  # @return [Manifest]                Un-persisted Manifest instance.
  #
  def new_manifest(opt = nil)
    opt ||= get_manifest_params
    opt[:name] ||= Manifest.default_name
    Manifest.new(opt)
  end

  # Create and persist a new manifest.
  #
  # @param [Hash, nil] opt              Default: `#get_manifest_params`.
  #
  # @return [Manifest]                  New persisted Manifest instance.
  #
  def create_manifest(opt = nil)
    opt ||= get_manifest_params
    Manifest.create!(opt)
  end

  # Start editing an existing manifest.
  #
  # @param [Manifest, Hash, nil] item   If present, used as a template.
  # @param [Hash, nil]           opt    Default: `#manifest_request_params`.
  #
  # @return [Manifest, nil]
  #
  def edit_manifest(item = nil, opt = nil)
    item, opt = manifest_request_params(item, opt)
    get_manifest(item, **opt).tap do |manifest|
      if manifest.nil?
        Log.debug { "#{__method__}: not found: item: #{item.inspect}" }
      end
    end
  end

  # Persist changes to an existing manifest.
  #
  # @param [Manifest, Hash, nil] item       If present, used as a template.
  # @param [Hash, nil]           opt        Default: `#manifest_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest, nil]
  #
  def update_manifest(item = nil, opt = nil)
    item, opt = manifest_request_params(item, opt)
    get_manifest(item).tap do |manifest|
      if manifest.nil?
        Log.debug { "#{__method__}: not found: item: #{item.inspect}" }
      else
        manifest.update!(opt)
      end
    end
  end

  # For the 'delete' endpoint...
  #
  # @param [String, Manifest, Array, nil] items
  # @param [Hash, nil]                    opt   Def: `#manifest_request_params`
  #
  # @raise [RangeError]               If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]         From Record::Searchable#search_records.
  #
  def delete_manifest(items = nil, opt = nil)
    items, opt = manifest_request_params(items, opt)
    id_opt  = extract_hash!(opt, :ids, :id)
    items ||= id_opt.values.first
    Manifest.search_records(*items, **opt)
  end

  # For the 'destroy' endpoint... # TODO: ?
  #
  # @param [String, Manifest, Array, nil] items
  # @param [Hash, nil]                    opt   Def: `#manifest_request_params`
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed entries.
  #
  def destroy_manifest(items = nil, opt = nil)
    items, opt = manifest_request_params(items, opt)
    opt.reverse_merge!(model_options.all)
    ids   = extract_hash!(opt, :ids, :id).values.first
    items = [*items, *ids].map! { |item| item.try(:id) || item }
    succeeded = []
    failed    = []
    Manifest.where(id: items).each do |item|
      if item.destroy
        succeeded << item.id
      else
        failed << item.id
      end
    end
    failure(:destroy, failed.uniq) if failed.present?
    succeeded
  end

  # ===========================================================================
  # :section: Workflow
  # ===========================================================================

  public

  # Persist changes to an existing manifest and update the saved state of all
  # associated rows.
  #
  # @param [Manifest, Hash, nil] item       If present, used as a template.
  # @param [Hash, nil]           opt        Default: `#manifest_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest, nil]
  #
  # @see file:assets/javascripts/controllers/manifest-edit.js *saveUpdates()*
  #
  def save_changes(item = nil, opt = nil)
    item, opt = manifest_request_params(item, opt)
    get_manifest(item).tap do |manifest|
      if manifest.nil?
        Log.debug { "#{__method__}: not found: item: #{item.inspect}" }
      else
        manifest.save_changes!(**opt)
      end
    end
  end

  # Back out of provisional changes to associated rows.
  #
  # @param [Manifest, Hash, nil] item       If present, used as a template.
  # @param [Hash, nil]           opt        Default: `#manifest_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest, nil]
  #
  # @see file:assets/javascripts/controllers/manifest-edit.js *cancelUpdates()*
  #
  def cancel_changes(item = nil, opt = nil)
    item, opt = manifest_request_params(item, opt)
    get_manifest(item).tap do |manifest|
      if manifest.nil?
        Log.debug { "#{__method__}: not found: item: #{item.inspect}" }
      else
        manifest.cancel_changes!(**opt)
      end
    end
  end

  # ===========================================================================
  # :section: Workflow
  # ===========================================================================

  public

  # Validate readiness of a manifest to start transmission.
  #
  # @param [Manifest, Hash, nil] item       If present, used as a template.
  # @param [Hash, nil]           opt        Default: `#manifest_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest, nil]
  #
  def remit_manifest(item = nil, opt = nil)
    item, opt = manifest_request_params(item, opt)
    get_manifest(item).tap do |manifest|
      if manifest.nil?
        Log.debug { "#{__method__}: not found: item: #{item.inspect}" }
      else
        # TODO: validate readiness to start transmission
      end
    end
  end

  # Start transmission of a manifest.
  #
  # @param [Manifest, Hash, nil] item       If present, used as a template.
  # @param [Hash, nil]           opt        Default: `#manifest_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest, nil]
  #
  def start_manifest(item = nil, opt = nil)
    item, opt = manifest_request_params(item, opt)
    get_manifest(item).tap do |manifest|
      if manifest.nil?
        Log.debug { "#{__method__}: not found: item: #{item.inspect}" }
      else
        # TODO: start manifest transmission
        # TODO: create Bulk record
        #   - id          UUID      Unique identifier
        #   - manifest_id UUID      Owning manifest
        #   - created_at  DateTime  Start time
        #   - updated_at  DateTime  ...
        #   - finished_at DateTime  Time completed or canceled
        #   - canceled    Boolean   Canceled state (manual)
        #   - paused      Boolean   Paused state (manual)
        #   - halted      Boolean   Halted due to failures
        # TODO: Bulk.create(manifest_id: manifest.id, created_at: Time.now)
      end
    end
  end

  # Terminate transmission of a manifest.
  #
  # @param [Manifest, Hash, nil] item       If present, used as a template.
  # @param [Hash, nil]           opt        Default: `#manifest_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest, nil]
  #
  def stop_manifest(item = nil, opt = nil)
    item, opt = manifest_request_params(item, opt)
    get_manifest(item).tap do |manifest|
      if manifest.nil?
        Log.debug { "#{__method__}: not found: item: #{item.inspect}" }
      else
        # TODO: abort manifest transmission
        # TODO: Bulk.find(manifest_id: manifest.id).update!(canceled: true)
      end
    end
  end

  # Pause transmission of a manifest.
  #
  # @param [Manifest, Hash, nil] item       If present, used as a template.
  # @param [Hash, nil]           opt        Default: `#manifest_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest, nil]
  #
  def pause_manifest(item = nil, opt = nil)
    item, opt = manifest_request_params(item, opt)
    get_manifest(item).tap do |manifest|
      if manifest.nil?
        Log.debug { "#{__method__}: not found: item: #{item.inspect}" }
      else
        # TODO: Bulk.find(manifest_id: manifest.id).update!(paused: true)
      end
    end
  end

  # Resume transmission of a paused manifest.
  #
  # @param [Manifest, Hash, nil] item       If present, used as a template.
  # @param [Hash, nil]           opt        Default: `#manifest_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest, nil]
  #
  def resume_manifest(item = nil, opt = nil)
    item, opt = manifest_request_params(item, opt)
    get_manifest(item).tap do |manifest|
      if manifest.nil?
        Log.debug { "#{__method__}: not found: item: #{item.inspect}" }
      else
        # TODO: Bulk.find(manifest_id: manifest.id).update!(paused: false)
      end
    end
  end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  public

  # Generate a response to a POST.
  #
  # @param [Symbol, Integer, Exception, nil] status
  # @param [*]                               item
  # @param [Hash]                            opt
  #
  # @return [void]
  #
  def post_response(status, item = nil, **opt)
    opt[:meth]     ||= calling_method
    opt[:tag]      ||= "MANIFEST #{opt[:meth]}"
    opt[:fallback] ||= manifest_index_path
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Raise an exception.
  #
  # @param [Symbol, String, Array<String>, ExecReport, Exception, nil] problem
  # @param [Any, nil]                                                  value
  #
  # @raise [Record::SubmitError]
  # @raise [ExecError]
  #
  # @see ExceptionHelper#failure
  #
  def failure(problem, value = nil)
    ExceptionHelper.failure(problem, value, model: :manifest)
  end

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  # Create a @model_options instance from the current parameters.
  #
  # @return [Manifest::Options]
  #
  def set_model_options
    @model_options = Manifest::Options.new(request_parameters)
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

  # Create a Paginator for the current controller action.
  #
  # @param [Class<Paginator>] paginator  Paginator class.
  # @param [Hash]             opt        Passed to super.
  #
  # @return [Manifest::Paginator]
  #
  def pagination_setup(paginator: Manifest::Paginator, **opt)
    opt[:id] ||= identifier
    # noinspection RubyMismatchedReturnType
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)

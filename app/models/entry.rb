# app/models/entry.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An 'entries' table record which is a completed EMMA entry.
#
# @!attribute [r]  user_id
#   The user who submitted the entry.
#   (Set via initial Phase::Create action)
#
# @!attribute [rw] submission_id
#   The submission ID for the entry.
#   (Set via initial Phase::Create action)
#
# @!attribute [rw] repository
#   The repository associated with the entry.
#   (Set via initial Phase::Create action)
#
# @!attribute [rw] fmt
#   The format of the file.
#   (Set via Phase::Create or completed Phase::Edit)
#
# @!attribute [rw] ext
#   The extension of the file.
#   (Set via Phase::Create or completed Phase::Edit)
#
# @!attribute [rw] emma_data
#   JSON metadata from the file.
#   (Set via Phase::Create or completed Phase::Edit)
#
# @!attribute [rw] file_data
#   Shrine metadata for the file.
#   (Set via Phase::Create or completed Phase::Edit)
#
# @!attribute [r]  created_at
#   Time of record creation.
#
# @!attribute [rw] updated_at
#   Last time record was modified.
#
class Entry < ApplicationRecord

  DESTRUCTIVE_TESTING = false

  include Model

  include Record
  include Record::EmmaData
  include Record::Assignable
  include Record::Authorizable
  include Record::Controllable
  include Record::Describable
  include Record::Searchable
  include Record::Submittable
  include Record::Uploadable # NOTE: needed for #file_name
  include Record::Validatable

  include Record::Testing
  include Record::Debugging

  # Include modules from "app/models/entry/**.rb".
  include_submodules(self)

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    extend Record::Describable::ClassMethods
    # :nocov:
  end

  # ===========================================================================
  # :section: ActiveRecord validations
  # ===========================================================================

  belongs_to :user, optional: true

  has_many :phases # , dependent: :destroy # TODO: destroying an Entry should destroy its Phases ... but only if persisted
  has_many :actions, through: :phases

  # ===========================================================================
  # :section: ActiveRecord scopes # TODO: keep?
  # ===========================================================================

  DEF_REPO = EmmaRepository.default.to_s.freeze

  scope :native, ->(**opt) { where(repository: DEF_REPO, **opt).order(:id) }

  scope :non_native, ->(**opt) do
    where.not(repository: DEF_REPO).order(:id).then do |result|
      opt.present? ? result.and(where(**opt)) : result
    end
  end

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash, Entry] attr         Passed to #assign_attributes via super.
  # @param [Proc]        block        Passed to super.
  #
  # This method overrides:
  # @see ActiveRecord::Core#initialize
  #
  def initialize(attr = nil, &block)
    __debug_items(binding)
    attr = attr.attributes if attr.is_a?(Entry)
    attr = attr.merge(initializing: true).except!(:reset) if attr.is_a?(Hash)
    super(attr, &block)
    __debug_items(leader: 'new ENTRY') { self }
  end

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Update database fields, including the structured contents of the :emma_data
  # field.
  #
  # @param [Hash, ActionController::Parameters, Model, nil] attr
  # @param [Hash, nil]                                      opt
  #
  # @return [void]
  #
  # @see Record::EmmaData#EMMA_DATA_KEYS
  #
  def assign_attributes(attr, opt = nil)
    __debug_items(binding)
    data = extract_hash!(attr, *EMMA_DATA_KEYS)
    attr = attribute_options(attr, opt)
    attr[:emma_data] = generate_emma_data(data, attr)
    super(attr, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The latest phase, representing the current status of the entry.
  #
  # @return [Phase, nil]
  #
  def current_phase
    phases.order(:updated_at).last
  end

  # Get Phase records associated with this record for the phase given either
  # as *phase_type* or `opt[:type]`.
  #
  # @param [Symbol,String,Phase,Class,nil] phase_type   Def: #current_phase.
  # @param [Hash]                          opt          For #where.
  #
  # @return [ActiveRecord::Relation<Phase>]
  #
  # == Examples
  #
  # @example Creation event
  #   define_method(:creates) { phase_scope(:create).last }
  #
  # @example Edit events
  #   define_method(:edits) { phase_scope(:edit) }
  #
  # @example Removal event
  #   define_method(:removes) { phase_scope(:remove) }
  #
  # @example Review events
  #   define_method(:reviews) { phase_scope(:review) }
  #
  def phase_scope(phase_type = nil, **opt)
    opt[:type] = Phase.type(phase_type || opt[:type] || current_phase)
    phases.where(**opt).order(:id)
  end

  # Create a new Phase for this Entry, initializing it with the current values
  # from this record.
  #
  # @param [Symbol, String, nil] type     If *nil*, opt[:type] must be present.
  # @param [Hash]                opt      Passed to ActiveRecord#create!
  #
  # @raise [Record::SubmitError]            If type not given.
  # @raise [ActiveRecord::RecordInvalid]    Update failed due to validations.
  # @raise [ActiveRecord::RecordNotSaved]   Update halted due to callbacks.
  #
  # @return [Phase]
  #
  def generate_phase(type, **opt)
    type ||= opt[:type] or failure("#{__method__}: no type given")
    opt[:type]  = Phase.type(type)
    opt[:state] = :started
    opt[:from]  = self
    phases.create!(opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get user(s) for the given phase associated with this record.
  #
  # @param [Symbol, String, Phase, Class] phase_type
  #
  # @return [Array<User>]
  #
  def users(phase_type)
    # noinspection RailsParamDefResolve
    ids = phase_scope(phase_type).pluck(:user_id)
    User.where(id: ids).order(:id).to_a
  end

  # The user who submitted the entry.
  #
  # @return [User, nil]
  #
  def submitter
    users(:Create).tap { |result|
      Log.warn { "Entry #{id}: #{result.size} submitters" } if result.size != 1
    }.last
  end

  # The user(s) who modified the entry.
  #
  # @return [Array<User>]
  #
  def editors
    users(:Edit).tap do |result|
      Log.info { "Entry #{id}: #{result.size} editors" } if result.size > 1
    end
  end

  # The user who removed the entry.
  #
  # @return [User, nil]
  #
  def remover
    users(:Remove).tap { |result|
      Log.warn { "Entry #{id}: #{result.size} removers" } if result.size > 1
    }.last
  end

  # The user(s) who reviewed the entry.
  #
  # @return [Array<User>]
  #
  def reviewers
    users(:Review).tap do |result|
      Log.info { "Entry #{id}: #{result.size} reviewers" } if result.size > 1
    end
  end

  # uploaders # TODO: keep ???
  #
  # @return [Array<User>]
  #
  def uploaders
    ids = actions.where(type: %i[Store BatchStore]).pluck(:user_id)
    User.where(id: ids).order(:id).to_a
  end

  # ===========================================================================
  # :section: Record::Searchable::ClassMethods overrides
  # ===========================================================================

  public

  # Get the latest matching Entry record.
  #
  # @param [Model, Hash, String, Symbol, nil] sid
  # @param [Hash]                             opt
  #
  # @raise [Record::StatementInvalid]   If *sid*/opt[:submission_id] invalid.
  # @raise [Record::NotFound]           If record not found.
  #
  # @return [Entry]
  #
  def self.latest_for_sid(sid = nil, **opt)
    opt[:sort] = :created_at unless opt.key?(:sort)
    opt[:max]  = 1           unless opt.key?(:max)
    # noinspection RubyMismatchedReturnType
    super(sid, **opt)
  end

  # ===========================================================================
  # :section: Record::Identification::ClassMethods overrides
  # ===========================================================================

  protected

  # Counter for the trailing portion of the generated submission ID.
  #
  # This provides a per-thread value in the range 0..99 which can be used to
  # differentiate submission IDs which are generated in rapid succession (e.g.,
  # for bulk upload).
  #
  # @return [Integer]
  #
  #--
  # noinspection RbsMissingTypeSignature
  #++
  def self.sid_counter                                                          # NOTE: from Upload::IdentifierMethods
    @sid_counter &&= (@sid_counter + 1) % 100
    @sid_counter ||= rand(100) % 100
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @return [String]
  #
  def self.describe_type(*)
    '%{submission}'
  end

  # A textual description of the status of the Entry instance. # TODO: I18n
  #
  # @param [Entry] entry
  # @param [Hash]  opt                To Phase#describe_status except for:
  #
  # @option opt [Phase] :phase        Default: `#current_phase`.
  #
  # @return [String]
  #
  def self.describe_status(entry, **opt)
    phase  = opt.delete(:phase) || entry.current_phase
    note   = opt.delete(:note)  || describe_type(entry, **opt)
    note   = interpolations(note, entry, **opt)
    status = phase&.describe_status(**opt) || "created at #{entry.created_at}"
    [note, status].compact.join(' ')
  end

  # ===========================================================================
  # :section: Record::Debugging overrides
  # ===========================================================================

  public

  if DEBUG_RECORD

    def show
      super(:user, :phases, :actions)
    end

    def self.show
      super(:native, :non_native)
    end

  end

end

__loading_end(__FILE__)

# test/test_helper/samples.rb
#
# frozen_string_literal: true
# warn_indent:           true

require_relative 'utility'

# Access to sample models.
#
module TestHelper::Samples

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A string added to the start of each title created on a non-production
  # instance to help distinguish it from other index results.
  #
  # @type [String]
  #
  TITLE_PREFIX = UploadWorkflow::Properties::UPLOAD_DEV_TITLE_PREFIX

  # File fixture for Uploads.
  #
  # @type [String]
  #
  UPLOAD_FILE = 'pg2148.epub'

end

class SampleGenerator

  include TestHelper::Utility

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Suitable files in 'test/fixtures' will define these fixtures.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  FIXTURE = {
    new:      :example,
    create:   :example,
    edit:     :edit_example,
    update:   :edit_example,
    delete:   :delete_example,
    destroy:  :delete_example,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The test class creating this instance in its #setup block.
  #
  # @type [ActiveSupport::TestCase]
  #
  attr_accessor :context

  # Create a new instance.
  #
  # @param [ActiveSupport::TestCase] context
  # @param [Hash]                    opt
  #
  # @option opt [Class]  :model_class
  # @option opt [String] :fixture_name
  #
  def initialize(context, **opt)
    @context      = context
    @model_class  = opt[:model_class]
    @fixture_name = opt[:fixture_name]
  end

  # ===========================================================================
  # :section: TestHelper::Common overrides
  # ===========================================================================

  public

  # Derive the class of the associated model from the given source, using the
  # MODEL constant if available.
  #
  # @param [any, nil] item      Symbol, String, Class, Model; def: `#context`
  #
  # @return [Class]
  #
  def model_class(item = nil)
    # noinspection RubyMismatchedReturnType
    item ? super : (@model_class ||= super(context))
  end

  # The name of the fixture set for the indicated model type.
  #
  # @param [Symbol, String, Class, ApplicationRecord] item
  #
  # @return [String]
  #
  def fixture_name(item = nil)
    item ? super : (@fixture_name ||= super(model_class))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  # @type [String, Integer, nil]
  attr_accessor :edit_id

  # @private
  # @type [String, Integer, nil]
  attr_accessor :delete_id

  # Invoke the method associated with *action*.
  #
  # @param [Symbol] action
  # @param [Hash]   opt               Passed to the generation method.
  #
  # @return [Model]
  #
  def sample_for(action, **opt, &blk)
    send(:"sample_for_#{action}", **opt, &blk)
  end

  # Create a new un-persisted item for the purpose of supplying field values to
  # an item submission form.
  #
  # @param [Model,Hash,Symbol] src    The exemplar record or fixture name.
  # @param [Hash]              opt    Additional field values.
  #
  # @return [Model]
  #
  def sample_for_new(src: FIXTURE[:new], **opt, &blk)
    new_item(src, **opt, &blk)
  end

  # Create a new un-persisted item for the purpose of supplying field values to
  # submit a new item to the database.
  #
  # @param [Model,Hash,Symbol] src    The exemplar record or fixture name.
  # @param [Hash]              opt    Additional field values.
  #
  # @return [Model]
  #
  def sample_for_create(src: FIXTURE[:create], **opt, &blk)
    sample_for_new(src: src, **opt, &blk)
  end

  # Push a dummy item into the database for the purpose of supplying field
  # values to an item edit form.
  #
  # @param [Model,Hash,Symbol] src    The exemplar record or fixture name.
  # @param [Hash]              opt    Additional field values.
  #
  # @return [Model]
  #
  def sample_for_edit(src: FIXTURE[:edit], **opt, &blk)
    current = edit_id && model_class.find_by(id: edit_id)
    current&.delete
    new_record(src, **opt, &blk).tap do |record|
      self.edit_id = record.id
    end
  end

  # Push a dummy item into the database for editing.
  #
  # @param [Model,Hash,Symbol] src    The exemplar record or fixture name.
  # @param [Hash]              opt    Additional field values.
  #
  # @return [Model]
  #
  def sample_for_update(src: FIXTURE[:update], **opt, &blk)
    sample_for_edit(src: src, **opt, &blk)
  end

  # Push a dummy item into the database for deletion.
  #
  # @param [Model,Hash,Symbol] src    The exemplar record or fixture name.
  # @param [Hash]              opt    Additional field values.
  #
  # @return [Model]
  #
  def sample_for_delete(src: FIXTURE[:delete], **opt, &blk)
    current = delete_id && model_class.find_by(id: delete_id)
    return current if current && (src == FIXTURE[:delete])
    current&.delete
    new_record(src, **opt, &blk).tap do |record|
      self.delete_id = record.id
    end
  end

  # Push a dummy item into the database for deletion.
  #
  # @param [Model,Hash,Symbol] src    The exemplar record or fixture name.
  # @param [Hash]              opt    Additional field values.
  #
  # @return [Model]
  #
  def sample_for_destroy(src: FIXTURE[:destroy], **opt, &blk)
    sample_for_delete(src: src, **opt, &blk)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Invoke #new_record with the appropriate fixture for *action*.
  #
  # @param [Symbol] action
  # @param [Hash]   opt               Passed to #new_record.
  #
  # @return [Model]
  #
  def new_record_for(action, **opt, &blk)
    src = opt.delete(:src) || FIXTURE[action]
    new_record(src, **opt, &blk)
  end

  # Generate a new persisted item record based on *src*.
  #
  # @param [Model,Hash,Symbol,nil] src  An exemplar record or fixture name.
  # @param [Hash]                  opt  Passed to #new_item.
  # @param [Proc]                  blk  Passed to #new_item.
  #
  # @return [Model]
  #
  def new_record(src = nil, **opt, &blk)
    new_item(src, **opt, &blk).tap(&:save!)
  end

  # Generate a new un-persisted item record based on *src*.
  #
  # @param [Model,Hash,Symbol,nil] src  An exemplar record or fixture name.
  # @param [Hash]                  opt  Passed to #fields.
  # @param [Proc]                  blk  Passed to #fields.
  #
  # @return [Model]
  #
  def new_item(src = nil, **opt, &blk)
    attr = fields(src, **opt, &blk).except(:id)
    model_class.new(attr)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Invoke #fields with the appropriate fixture for *action*.
  #
  # @param [Symbol] action
  # @param [Hash]   opt               Passed to #fields.
  #
  # @return [Hash]
  #
  def fields_for(action, **opt, &blk)
    src = opt.delete(:src) || FIXTURE[action]
    fields(src, **opt, &blk)
  end

  # Generate field values based on *src*.
  #
  # @param [Model,Hash,Symbol,nil] src  An exemplar record or fixture name.
  # @param [Hash]                  opt  Additional field values except for
  #                                       #FIELDS_OPT which are passed to the
  #                                       block.
  #
  # @return [Hash]
  #
  # @yield [attr] Expose fields for adjustment.
  # @yieldparam [Hash] attr   Field values for the new record.
  # @yieldreturn [void]       The block may update *attr* directly.
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def fields(src = nil, **opt, &blk)
    fld = opt.slice!(*FIELDS_OPT) # Extract any additional field values.
    src = :example     if src.nil?
    src = fixture(src) if src.is_a?(Symbol)
    src = (src.try(:fields) || src.try(:to_h) || {}).merge(fld)
    if blk
      case opt[:preserve]
        when true then opt.except!(:preserve).reverse_merge!(force: false)
        else           set_field_option!(opt, :preserve)
      end
      case opt[:mutate]
        when true then opt.except!(:mutate).reverse_merge!(force: true)
        else           set_field_option!(opt, :mutate)
      end
      blk.call(src, **opt)
    end
    src
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Used within #fields overrides to provide values to specific fields.
  #
  # @param [Hash]      attr
  # @param [Hash, nil] preserve
  # @param [Hash, nil] mutate
  # @param [Boolean]   force
  # @param [Hash]      opt
  #
  # @yield Provide field value setters.
  # @yieldreturn [Hash{Symbol=>Proc}]
  #
  def set_field(attr, preserve: nil, mutate: nil, force: :unset, **opt)
    existing = (force == :unset) ? opt.blank? : !force
    yield.each_pair do |field, value|
      val = -> { value.is_a?(Proc) ? value.call : value }
      if preserve&.key?(field)
        attr[field] = val.call unless attr.key?(field)
      elsif mutate&.key?(field)
        attr[field] = mutate[field].is_a?(TrueClass) ? val.call : mutate[field]
      elsif existing
        attr[field] = val.call if attr[field].nil?
      else
        attr[field] = val.call
      end
    end
  end

  # Transform a provided option value into a Hash or remove it if it is blank.
  #
  # @param [Hash]   opt
  # @param [Symbol] key
  #
  # @return [void]
  #
  def set_field_option!(opt, key)
    return unless opt.key?(key)
    value = opt[key].presence
    value = [value]                               if value.is_a?(Symbol)
    value = value.compact.map { [_1, true] }.to_h if value.is_a?(Array)
    value.is_a?(Hash) ? opt.merge!(key => value) : opt.delete(key)
  end

  # Get the indicated fixture record.
  #
  # @param [Symbol] name
  #
  # @return [Model, nil]
  #
  def fixture(name)
    context.send(fixture_name, name)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Local options for #set_field.
  #
  # @type [Array<Symbol>]
  #
  SET_FIELD_OPT = method_key_params(:set_field).freeze

  # Options for #fields.
  #
  # @type [Array<Symbol>]
  #
  FIELDS_OPT = [*SET_FIELD_OPT, *UNIQUE_NAME_OPT].uniq.freeze

end

class ManifestSampleGenerator < SampleGenerator

  # ===========================================================================
  # :section: SampleGenerator overrides
  # ===========================================================================

  public

  # Generate field values based on *src*.
  #
  # @param [Model,Hash,Symbol,nil] src  An exemplar record or fixture name.
  # @param [Hash]                  opt  Additional field values except for
  #                                       #FIELDS_OPT which are passed to the
  #                                       block, and local:
  #
  # @option opt [User] :user            Calling user.
  #
  # @return [Hash]
  #
  def fields(src = nil, **opt, &blk)
    user = opt.delete(:user)
    return super if blk
    # noinspection RubyScope
    super do |attr, **opt|
      set_field(attr, **opt) {{
        name:    -> { manifest_name(attr, **opt) },
        user_id: -> { user&.id || attr[:user_id] },
      }}
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  def manifest_name(item = nil, **opt)
    opt[:base] ||= item && item[:name]
    unique_name(**opt)
  end

end

class OrgSampleGenerator < SampleGenerator

  # ===========================================================================
  # :section: SampleGenerator overrides
  # ===========================================================================

  public

  # Generate field values based on *src*.
  #
  # @param [Model,Hash,Symbol,nil] src  An exemplar record or fixture name.
  # @param [Hash]                  opt  Additional field values except for
  #                                       #FIELDS_OPT which are passed to the
  #                                       block.
  #
  # @return [Hash]
  #
  # @yield [attr] Expose fields for adjustment.
  # @yieldparam [Hash] attr   Field values for the new record.
  # @yieldreturn [void]       The block may update *attr* directly.
  #
  def fields(src = nil, **opt, &blk)
    return super if blk
    # noinspection RubyScope
    super do |attr, **opt|
      set_field(attr, **opt) {{
        long_name:  -> { org_name(attr, **opt) },
        short_name: -> { attr[:long_name].scan(/[[:upper:]]/).join }
      }}
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  def org_name(item = nil, **opt)
    opt[:base] ||= item && item[:long_name]
    unique_name(**opt)
  end

end

class UploadSampleGenerator < SampleGenerator

  include Emma::Json

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  # @type [String, Integer, nil]
  attr_accessor :create_id

  # ===========================================================================
  # :section: SampleGenerator overrides
  # ===========================================================================

  public

  # Push a dummy item into the database in the 'validating' state.
  #
  # @param [Hash] opt               Passed to super.
  #
  # @return [Upload]
  #
  def sample_for_create(**opt, &blk)
    current = create_id && model_class.find_by(id: create_id)
    current&.delete
    # noinspection RubyMismatchedReturnType
    super.tap do |record|
      self.create_id = record.id if record.save!
      record.set_state('validating')
    end
  end

  # Push a dummy item into the database for editing in the 'validating' state.
  #
  # @param [Hash] opt               Passed to super.
  #
  # @return [Upload]
  #
  def sample_for_update(**opt, &blk)
    # noinspection RubyMismatchedReturnType
    super.tap do |record|
      record.set_state('validating')
    end
  end

  # ===========================================================================
  # :section: SampleGenerator overrides
  # ===========================================================================

  public

  # Generate field values based on *src*.
  #
  # @param [Model,Hash,Symbol,nil] src  An exemplar record or fixture name.
  # @param [Hash]                  opt  Additional field values except for
  #                                       #FIELDS_OPT which are passed to the
  #                                       block.
  #
  # @return [Hash]
  #
  # @yield [attr] Expose fields for adjustment.
  # @yieldparam [Hash] attr   Field values for the new record.
  # @yieldreturn [void]       The block may update *attr* directly.
  #
  def fields(src = nil, **opt, &blk)
    opt[:mutate] = opt[:mutate].dup if opt[:mutate].is_a?(Hash)
    opt[:mutate] = { mutate: true } if opt[:mutate].is_a?(TrueClass)
    opt[:mutate] = {}               unless opt[:mutate].is_a?(Hash)
    opt[:mutate].reverse_merge!(submission_id: true)
    return super if blk
    # noinspection RubyScope
    super do |attr, **opt|
      emma_data = attr.delete(:emma_data).presence
      emma_data = emma_data && Upload.parse_emma_data(emma_data) || {}
      file_data = attr.delete(:file_data).presence
      file_data = file_data && json_parse(file_data)&.dig(:metadata) || {}
      attr.merge!(emma_data, file_data)
      set_field(attr, **opt) {{
        submission_id:  -> { Upload.generate_submission_id },
        dc_title:       -> { upload_title(attr, **opt) },
        dc_creator:     -> { upload_author(attr, **opt) },
      }}
      if attr[:dc_creator].is_a?(Array)
        attr[:dc_creator] = attr[:dc_creator].join("\n")
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate a distinct submission title.
  #
  # @param [Upload, Hash, nil] item
  # @param [Hash]              opt    Options for #unique_name.
  #
  # @return [String]
  #
  def upload_title(item = nil, **opt)
    opt[:base] &&= [*opt[:base], 'TITLE'].join(' - ')
    case item
      when Upload then opt[:base] ||= item.emma_metadata[:dc_title]
      when Hash   then opt[:base] ||= item[:dc_title]
    end
    unique_name(**opt)
  end

  # Generate a distinct submission author.
  #
  # @param [Upload, Hash, nil] item
  # @param [Hash]              opt    Options for #unique_name.
  #
  # @return [String]
  #
  def upload_author(item = nil, **opt)
    opt[:base] &&= [*opt[:base], 'AUTHOR'].join(' - ')
    case item
      when Upload then opt[:base] ||= item.emma_metadata[:dc_creator]
      when Hash   then opt[:base] ||= item[:dc_creator]
    end
    unique_name(**opt)
  end

end

class UserSampleGenerator < SampleGenerator

  # ===========================================================================
  # :section: SampleGenerator overrides
  # ===========================================================================

  public

  # Generate field values based on *src*.
  #
  # @param [Model,Hash,Symbol,nil] src  An exemplar record or fixture name.
  # @param [Hash]                  opt  Additional field values except for
  #                                       #FIELDS_OPT which are passed to the
  #                                       block, and local:
  #
  # @option opt [User] :user            Calling user.
  #
  # @return [Hash]
  #
  def fields(src = nil, **opt, &blk)
    user = opt.delete(:user)
    return super if blk
    org  = user && !user.administrator? && user.org_id
    # noinspection RubyScope
    super do |attr, **opt|
      set_field(attr, **opt) {{
        email:            -> { unique_email(attr, **opt) },
        preferred_email:  -> { "alias_#{attr[:email]}" },
        org_id:           -> { org || attr[:org_id] },
      }}
    end
  end

end

# test/test_helper/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Common values for tests.
#
module TestHelper::Common

  include Emma::Common

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEST_TYPES = %w[channel controller decorator helper mailer model].freeze

  # The full directory path for "/test/test_helper".
  #
  # @type [String]
  #
  HELPER_DIR = File.expand_path(File.dirname(__FILE__)).freeze

  # The full directory path for "/test".
  #
  # @type [String]
  #
  TESTS_DIR  = File.expand_path("#{HELPER_DIR}/..").freeze

  # The full directory path for "/test/system".
  #
  # @type [String]
  #
  SYSTEM_DIR = "#{TESTS_DIR}/system"

  # The bases of controller names which are not plurals of model names.
  #
  # @type [Array<String>]
  #
  SINGLE = %w[
    data
    health
    help
    home
    metrics
    search
    sys
    tool
    user_sessions
  ].freeze

  # Controllers being tested in "/test/system/*_test.rb".
  #
  # @type [Array<Symbol>]
  #
  SYSTEM_CONTROLLERS =
    Dir["#{SYSTEM_DIR}/*_test.rb"].map { |path|
      ctrlr = File.basename(path, '.rb').delete_suffix('_test')
      ctrlr = ctrlr.singularize unless SINGLE.include?(ctrlr)
      ctrlr.to_sym
    }.sort.freeze

  # Properties which drive parameterized system tests.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  PROPERTY =
    ApplicationHelper::CONTROLLER_CONFIGURATION.map { |ctrlr, entry|
      next unless SYSTEM_CONTROLLERS.include?(ctrlr)
      next unless (actions = entry[:action]).present?
      unit  ||= entry.dig(:pagination, :count)
      unit  &&= unit.is_a?(Hash) ? unit[:one] : unit
      unit  ||= entry[:unit]
      unit  &&= unit.is_a?(Hash) ? unit[:brief] : unit
      unit  ||= ctrlr.to_s
      actions =
        actions.deep_dup.map { |action, config|
          entry  = (action == :index) ? 'list-item' : 'details'
          config[:heading]   ||= config[:title]
          config[:title]       = config[:label] || config[:heading]
          config[:count]     ||= unit.pluralize
          config[:body_css]  ||= ".#{ctrlr}-#{action}"
          config[:entry_css] ||= ".#{ctrlr}-#{entry}"
          [action, config]
        }.to_h
      [ctrlr, actions]
    }.compact.to_h.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # property
  #
  # @param [Symbol, String, Class, Model, nil] ctrlr
  # @param [Array<Symbol>]                     traversal
  # @param [any, nil]                          default
  #
  # @return [any, nil]
  #
  def property(ctrlr, *traversal, default: nil)
    controller = controller_name(ctrlr)
    PROPERTY.dig(controller, *traversal) || default
  end

  # The title (:h1 text value) for the given parameters.
  #
  # @param [Model, nil] item
  # @param [Symbol]     controller    Default: self
  # @param [Symbol]     action        Default: :index
  # @param [Symbol]     prop_key      End of #PROPERTY traversal.
  # @param [Hash]       opt           Override interpolation values.
  #
  # @raise [Minitest::Assertion] If value could not be found or interpolated.
  #
  # @return [String]
  #
  def page_title(
    item =      nil,
    controller: nil,
    action:     :index,
    prop_key:   :heading,
    **opt
  )
    value = property(controller, action, prop_key)
    flunk "no :#{prop_key} for #{controller}/#{action}" if value.blank?
    interpolate(value, item, **opt).strip
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Text indicating an authentication failure.
  #
  # @type [String]
  #
  AUTH_FAILURE = I18n.t('devise.failure.unauthenticated').freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current user within a test.
  #
  # @return [User, nil]
  #
  def current_user
    @current_user
  end

  # Set the current test user.
  #
  # @param [String, Symbol, User, nil] user
  #
  # @return [User, nil]
  #
  def set_current_user(user)
    @current_user = find_user(user)
  end

  # Clear the current test user.
  #
  # @return [nil]
  #
  def clear_current_user
    set_current_user(nil)
  end

  # Indicate whether is an authenticated session.
  #
  def signed_in?
    current_user.present?
  end

  # Indicate whether is an anonymous session.
  #
  def not_signed_in?
    current_user.blank?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Table of formats and associated MIME media types.
  #
  # @type [Hash{Symbol=>String}]
  #
  MEDIA_TYPE = {
    any:  '*/*',
    html: 'text/html',
    json: 'application/json',
    text: 'text/plain',
    xml:  'application/xml',
  }.freeze

  # Table of MIME media types and associated formats.
  #
  # @type [Hash{String=>Symbol}]
  #
  REVERSE_MEDIA_TYPE = MEDIA_TYPE.invert.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The format type associated with the given value.
  #
  # @param [Symbol, String, nil] type
  #
  # @return [Symbol, nil]
  #
  def format_type(type)
    type &&= type.to_s.downcase or return
    type.include?('/') ? REVERSE_MEDIA_TYPE[type] : type.to_sym
  end

  # Indicate whether *type* is HTML.
  #
  # @param [Symbol, String, nil] type
  #
  def html?(type)
    format_type(type) == :html
  end

  # Indicate whether *type* is JSON.
  #
  # @param [Symbol, String, nil] type
  #
  # @note Currently unused.
  # :nocov:
  def json?(type)
    format_type(type) == :json
  end
  # :nocov:

  # Indicate whether *type* is XML.
  #
  # @param [Symbol, String, nil] type
  #
  # @note Currently unused.
  # :nocov:
  def xml?(type)
    format_type(type) == :xml
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Derive the name of the associated controller from the given source.
  #
  # @param [any, nil] item      Symbol, String, Class, Model; def: `self_class`
  #
  # @return [Symbol, nil]
  #
  def controller_name(item = nil)
    return item                   if item.is_a?(Symbol)
    item = self_class             if item.nil?
    item = item.name || ''        if item.is_a?(Class)
    item = item.class.name || ''  unless item.is_a?(String)
    item.underscore.tr('/', '_').split('_').tap { |part|
      part.pop if part.last == 'test'
      part.pop if TEST_TYPES.include?(part.last)
      singular = part.many? && (part[0] == 'user') || SINGLE.include?(part[-1])
      part[-1] = part[-1].singularize unless singular
    }.compact_blank.join('_').to_sym.presence
  end

  # Derive the name of the associated model from the given source.
  #
  # @param [any, nil] item      Symbol, String, Class, Model; def: `self_class`
  #
  # @return [Symbol, nil]
  #
  def model_name(item = nil)
    item = controller_name(item)
    (item == :account) ? :user : item
  end

  # Derive the class of the associated model from the given source, using the
  # MODEL constant if available.
  #
  # @param [any, nil] item      Symbol, String, Class, Model; def: `self_class`
  #
  # @return [Class, nil]
  #
  def model_class(item = nil)
    item = model_name(item)&.to_s&.camelize&.safe_constantize or return
    (item < ApplicationRecord) ? item : item.safe_const_get(:MODEL)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  # Non-functional hints for RubyMine type checking for the fixture accessor
  # methods defined by ActiveRecord::TestFixtures#fixtures.

  # :nocov:
  # noinspection RubyUnusedLocalVariable
  unless ONLY_FOR_DOCUMENTATION

    # Fixture accessor defined by ActiveRecord::TestFixtures#fixtures.
    # @param [Array<Symbol|String>] name
    # @return [Enrollment, Array<Enrollment>]
    def enrollments(*name) end

    # Fixture accessor defined by ActiveRecord::TestFixtures#fixtures.
    # @param [Array<Symbol|String>] name
    # @return [JobResult, Array<JobResult>]
    def job_results(*name) end

    # Fixture accessor defined by ActiveRecord::TestFixtures#fixtures.
    # @param [Array<Symbol|String>] name
    # @return [ManifestItem, Array<ManifestItem>]
    def manifest_items(*name) end

    # Fixture accessor defined by ActiveRecord::TestFixtures#fixtures.
    # @param [Array<Symbol|String>] name
    # @return [Manifest, Array<Manifest>]
    def manifests(*name) end

    # Fixture accessor defined by ActiveRecord::TestFixtures#fixtures.
    # @param [Array<Symbol|String>] name
    # @return [Org, Array<Org>]
    def orgs(*name) end

    # Fixture accessor defined by ActiveRecord::TestFixtures#fixtures.
    # @param [Array<Symbol|String>] name
    # @return [SearchCall, Array<SearchCall>]
    def search_calls(*name) end

    # Fixture accessor defined by ActiveRecord::TestFixtures#fixtures.
    # @param [Array<Symbol|String>] name
    # @return [SearchResult, Array<SearchResult>]
    def search_results(*name) end

    # Fixture accessor defined by ActiveRecord::TestFixtures#fixtures.
    # @param [Array<Symbol|String>] name
    # @return [Upload, Array<Upload>]
    def uploads(*name) end

    # Fixture accessor defined by ActiveRecord::TestFixtures#fixtures.
    # @param [Array<Symbol|String>] name
    # @return [User, Array<User>]
    def users(*name) end

  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

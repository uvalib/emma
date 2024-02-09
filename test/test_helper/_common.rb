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

  TEST_TYPES = %w[channel decorator controller helper mailer model].freeze

  # The full directory path for "/test/test_helper".
  #
  # @type [String]
  #
  HELPER_DIR = File.expand_path(File.dirname(__FILE__))

  # The full directory path for "/test".
  #
  # @type [String]
  #
  TESTS_DIR  = File.expand_path("#{HELPER_DIR}/..")

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
    SYSTEM_CONTROLLERS.map { |model|
      path = (model == :user_sessions) ? 'user.sessions' : model
      unit = %I[
        emma.#{path}.pagination.count.one
        emma.#{path}.pagination.count
        emma.#{path}.unit.brief
        emma.#{path}.unit
        emma.generic.unit.brief
      ]
      unit = config_item(unit, fallback: model.to_s)
      endpoints =
        config_section(path).map { |endpoint, config|
          next unless config.is_a?(Hash) && config[:_endpoint]
          config = config.except(:_endpoint).deep_dup
          entry  = (endpoint == :index) ? 'list-item' : 'details'
          config[:heading]   ||= config[:title]
          config[:title]       = config[:label] || config[:heading]
          config[:count]     ||= unit.pluralize
          config[:body_css]  ||= ".#{model}-#{endpoint}"
          config[:entry_css] ||= ".#{model}-#{entry}"
          [endpoint, config]
        }.compact.to_h
      [model, endpoints] unless endpoints.blank?
    }.compact.to_h.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # property
  #
  # @param [Symbol, String, Class, Model, nil] model
  # @param [Array<Symbol>]                     traversal
  # @param [any, nil]                          default
  #
  # @return [any, nil]
  #
  def property(model, *traversal, default: nil)
    ctrlr = controller_name(model || self)
    PROPERTY.dig(ctrlr, *traversal) || default
  end

  # The title (:h1 text value) for the given parameters.
  #
  # @param [Model, item] item
  # @param [Symbol]      controller   Default: self
  # @param [Symbol]      action       Default: :index
  # @param [Symbol]      prop_key     End of #PROPERTY traversal.
  # @param [Symbol]      meth         Calling method (for error reporting).
  # @param [Hash]        opt          Override interpolation values.
  #
  # @raise [Minitest::Assertion] If value could not be found or interpolated.
  #
  # @return [String]
  #
  def page_title(
    item =      nil,
    controller: nil,
    action:     nil,
    prop_key:   :heading,
    meth:       nil,
    **opt
  )
    action ||= :index
    if (value = property(controller, action, prop_key)).blank?
      fail "#{meth || __method__}: no :#{prop_key} for #{controller}/#{action}"
    end
    interpolate(value, item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Give the target controller for the current context.
  #
  # @return [Symbol]
  #
  def this_controller
    # noinspection RubyMismatchedReturnType
    controller_name(self_class)
  end

  # Derive the name of the model/controller from the given source.
  #
  # @param [any, nil] value           Symbol, String, Class, Model
  #
  # @return [Symbol, nil]
  #
  def controller_name(value)
    return value                    if value.nil? || value.is_a?(Symbol)
    value = value.name || ''        if value.is_a?(Class)
    value = value.class.name || ''  unless value.is_a?(String)
    value.underscore.tr('/', '_').split('_').tap { |part|
      part.pop if part.last == 'test'
      part.pop if TEST_TYPES.include?(part.last)
      singular = part.many? && (part[0] == 'user') || SINGLE.include?(part[-1])
      part[-1] = part[-1].singularize unless singular
    }.compact_blank.join('_').to_sym.presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  # Non-functional hints for RubyMine type checking for the fixture accessor
  # methods defined by ActiveRecord::TestFixtures#fixtures.

  # noinspection RubyUnusedLocalVariable
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

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

    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

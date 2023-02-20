# test/test_helper/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Common values for tests.
#
module TestHelper::Common

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEST_TYPES = %w(channel decorator controller helper mailer model).freeze

  # Controllers being tested.
  #
  # @type [Array<Symbol>]
  #
  CONTROLLERS = %i[
    home
    account
    artifact
    bs_api
    category
    edition
    health
    manifest
    member
    periodical
    reading_list
    search
    search_call
    title
    upload
    user_sessions
  ].freeze

  # Properties which drive parameterized system tests.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>*}}]
  #
  PROPERTY =
    CONTROLLERS.map { |model|
      path = (model == :user_sessions) ? 'emma.user.sessions' : "emma.#{model}"
      unit = %I[
        #{path}.pagination.count.one
        #{path}.pagination.count
        #{path}.unit.brief
        #{path}.unit
        emma.generic.unit.brief
      ]
      unit = I18n.t(unit.shift, default: [*unit, model.to_s])
      endpoints =
        I18n.t(path, default: {}).map { |endpoint, config|
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
  # @param [*]                                 default
  #
  # @return [*]
  #
  def property(model, *traversal, default: nil)
    model = controller_name(model || self)
    PROPERTY.dig(model, *traversal) || default
  end

  # The title (:h1 text value) for the given parameters.
  #
  # @param [Model, item] item
  # @param [Symbol]      controller   Default: self
  # @param [Symbol]      action       Default: :index
  # @param [Symbol]      prop_key     End of #PROPERTY traversal.
  # @param [Symbol]      meth         Calling method (for error reporting).
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
    **
  )
    meth   ||= __method__
    action ||= :index
    value    = property(controller, action, prop_key)
    fail "#{meth}: no :#{prop_key} for #{controller}/#{action}" if value.blank?
    if (refs = named_references(value)).present?
      error =
        if item.nil?
          'missing item'
        elsif (invalid = refs.select { |ref| !item.respond_to?(ref) }).present?
          'invalid keys %s' % invalid.map { |ref| quote(ref) }.join(', ')
        end
      fail "#{meth}: cannot interpolate #{value.inspect} - #{error}" if error
      value %= refs.map { |k| [k, item.send(k)] }.to_h
    end
    value.to_s
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
  # @param [Symbol, String, Class, Model, *] value
  #
  # @return [Symbol, nil]
  #
  def controller_name(value)
    return value             if value.nil? || value.is_a?(Symbol)
    value = value.name       if value.is_a?(Class)
    value = value.class.name unless value.is_a?(String)
    parts = value.underscore.tr('/', '_').split('_')
    parts.pop if parts.last == 'test'
    parts.pop if TEST_TYPES.include?(parts.last)
    unless (parts.first == 'user') && parts.many?
      parts[-1] = parts[-1].singularize
    end
    parts.join('_').to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

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
    account
    artifact
    bs_api
    category
    edition
    health
    member
    periodical
    reading_list
    search
    search_call
    title
    user_sessions
  ].freeze

  # Properties which drive parameterized system tests.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>*}}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
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
  # @param [Symbol, String, Class, nil] model
  # @param [Array<Symbol>]              traversal
  # @param [*]                          default
  #
  # @return [*]
  #
  def property(model, *traversal, default: nil)
    # noinspection RailsParamDefResolve
    model ||= try(:this_controller)
    PROPERTY.dig(model, *traversal) || default
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

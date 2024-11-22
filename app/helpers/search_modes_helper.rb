# app/helpers/search_modes_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for search options.
#
module SearchModesHelper

  include SessionDebugHelper

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether selecting a search menu value takes immediate effect.
  #
  # If not menu selection value(s) are only transmitted via the search submit
  # button.
  #
  # @type [Boolean]
  #
  IMMEDIATE_SEARCH = false

  # Search display style variants.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_STYLES = %i[compact grid aggregate].freeze

  # The default search display style.
  #
  # @type [Symbol]
  #
  DEFAULT_STYLE = :normal

  # Search result display variants.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_RESULTS = %i[title file].freeze

  # The default search result display.
  #
  # @type [Symbol]
  #
  DEFAULT_RESULTS = :title

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether selecting a search menu value takes immediate effect.
  #
  # If not menu selection value(s) are only transmitted via the search submit
  # button.
  #
  # @type [Boolean]
  #
  # === Usage Notes
  # This should normally be *false* because this is a mode of operation that is
  # generally not consider accessibility-friendly and, also, skews search call
  # statistics.
  #
  def immediate_search?
    @immediate_search ||= session['app.search.immediate']&.to_sym
    @immediate_search ||= IMMEDIATE_SEARCH.to_s.to_sym
    @immediate_search == :true
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the display mode for search results.
  #
  # @return [Symbol]
  #
  def results_type
    @results_type ||= session['app.search.results']&.to_sym || DEFAULT_RESULTS
  end

  # Indicate whether search results are displayed hierarchically (by title).
  #
  def title_results?
    results_type == :title
  end

  # Indicate whether search results are displayed literally (per file).
  #
  def file_results?
    results_type == :file
  end

  # Clear the display mode for search results.
  #
  # @return [void]
  #
  def reset_results_type
    @results_type = nil
  end

  # Ensure that search results are displayed hierarchically (by title).
  #
  # @return [Symbol]
  #
  # @note Currently unused.
  # :nocov:
  def force_title_results
    @results_type = :title
  end
  # :nocov:

  # Ensure that search results are displayed literally (per file).
  #
  # @return [Symbol]
  #
  def force_file_results
    @results_type = :file
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether search debug controls should be displayed.
  #
  def search_debug?
    session_debug?(:search)
  end

  # Indicate whether search dev controls should be displayed.
  #
  def search_dev?
    session_debug?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration conditionals.
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  CONFIG_CONDITION = {
    title_only: :title_results?,
    file_only:  :file_results?,
    debug_only: :search_debug?,
    dev_only:   :search_dev?,
  }.freeze

  # Indicate whether the guard condition is satisfied.
  #
  # @param [Array<Symbol,String>, Symbol, String, Boolean, nil] guard
  #
  def permitted_by?(guard)
    return false if false?(guard)
    return true  if true?(guard)
    return false if (guards = Array.wrap(guard).compact.map!(&:to_sym)).blank?
    # noinspection RubyMismatchedArgumentType
    guards.all? { (m = CONFIG_CONDITION[_1]).is_a?(Proc) ? m.call : try(m) }
  end

  # Normalize :enabled property values for use by #permitted_by?.
  #
  # @param [Array<Symbol,String,Boolean,nil>, Symbol, String, Boolean, nil] val
  #
  # @return [TrueClass, FalseClass, Array<Symbol>]
  #
  def self.guard_values(val)
    guards = Array.wrap(val).compact
    return false if guards.blank? || guards.any? { false?(_1) }
    return true  if guards.any? { true?(_1) }
    guards.map!(&:to_sym).uniq!
    if (invalid = guards - CONFIG_CONDITION.keys).present?
      invalid = invalid.first unless invalid.many?
      Log.warn("#{__method__}: not in CONFIG_CONDITION: #{invalid.inspect}")
    end
    guards
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the display style variant for search results.
  #
  # @return [Symbol]
  #
  def search_style
    @search_style ||= session['app.search.style']&.to_sym || DEFAULT_STYLE
  end

  # Indicate whether search results are displayed in the normal way.
  #
  # @note Currently unused.
  # :nocov:
  def default_style?
    search_style == DEFAULT_STYLE
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)

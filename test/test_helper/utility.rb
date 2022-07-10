# test/test_helper/utility.rb
#
# frozen_string_literal: true
# warn_indent:           true

# General utility methods.
#
module TestHelper::Utility

  include TestHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  CDN_URL = 'https://d1lp72kdku3ux1.cloudfront.net'

  # The URL for a catalog title thumbnail.
  #
  # @param [String] bookshare_id
  #
  # @return [String]
  #
  def cdn_thumbnail(bookshare_id)
    "#{CDN_URL}/title_instance/13e/small/%s.jpg" % bookshare_id
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return a User instance from the given identification.
  #
  # @param [String, Symbol, User, Any, nil] user
  #
  # @return [User]
  # @return [nil]                     If *user* could not be converted.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def find_user(user)
    user = nil                         if user == :anonymous
    user = user.sub(/@.*$/, '').to_sym if user.is_a?(String)
    user = users(user)                 if user.is_a?(Symbol)
    user                               if user.is_a?(User)
  end

  # Return multiple User instances.
  #
  # @param [Array] users
  #
  # @return [Array<User,nil>]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def find_users(*users)
    users = users.flatten
    users.map! { |u| u || :anonymous }
    users.map! { |u| (u == :anonymous) ? u : find_user(u) }.compact!
    users.map! { |u| (u == :anonymous) ? nil : u }
  end

  # The number of fixture records for the given model.
  #
  # @param [Model,Symbol,String] model
  #
  # @return [Integer]
  #
  def fixture_count(model)
    name = model.to_s.underscore.pluralize
    @loaded_fixtures[name]&.size || 0
  end

  # Extract the EMMA index entry identifier from the item.
  #
  # @param [SearchResult, nil] item
  # @param [String, nil]       repo
  # @param [String, nil]       rid
  # @param [String, nil]       format
  # @param [String, nil]       ver
  #
  # @return [String]
  #
  def record_id(item = nil, repo: nil, rid: nil, format: nil, ver: nil)
    # noinspection RubyNilAnalysis
    if item.is_a?(SearchResult)
      repo   ||= item.repository
      rid    ||= item.repositoryRecordId
      format ||= item.format
      ver    ||= item.formatVersion
    end
    [repo, rid, format].compact_blank!.tap { |parts|
      # noinspection RubyMismatchedArgumentType
      parts << ver if ver && (parts.size == 3)
    }.join('-')
  end

  # Note in the output that a test was skipped because it was not applicable.
  #
  # @param [String, nil] note         Additional annotation.
  #
  # @return [true]
  #
  def not_applicable(note = nil)
    $stderr.puts ['TEST SKIPPED', 'NOT APPLICABLE', note].compact.join(' - ')
    true
  end

  # Note in the output that a test was skipped because the given format was not
  # applicable (or if none was given whether any of the currently configured
  # formats in #TEST_FORMATS are applicable).
  #
  # @param [Array, Symbol, nil] fmt
  # @param [String, nil]        note  Additional annotation.
  # @param [Array, Symbol]      only  Applicable format(s).
  #
  # @return [true]                    If the test should proceed.
  # @return [false]                   If the test should be skipped.
  #
  def allowed_format(fmt = nil, note = nil, only:)
    fmt, note = [nil, fmt] if fmt.is_a?(String)
    return true if fmt.nil? && Array.wrap(only).intersect?(TEST_FORMATS)
    return true if Array.wrap(only).intersect?(Array.wrap(fmt))
    format = 'format'
    only   = only.first if only.is_a?(Array) && !only.many?
    msg    = ['TEST SKIPPED']

    if fmt.nil?
      format = format.pluralize if only.is_a?(Array)
      msg << "ONLY APPLICABLE for #{only.inspect} #{format}"

    elsif only.is_a?(Array)
      # noinspection RubyNilAnalysis
      format = format.pluralize if fmt.is_a?(Array) && fmt.many?
      msg << 'NOT APPLICABLE'
      msg << "#{format} #{fmt.inspect} not in #{only.inspect}"

    elsif fmt.is_a?(Array)
      format = format.pluralize if only.is_a?(Array)
      msg << "ONLY APPLICABLE for #{only.inspect} #{format}"

    else
      msg << "NOT APPLICABLE for #{fmt.inspect} #{format}"
    end

    $stderr.puts [*msg, note].compact.join(' - ')
    false
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
    # noinspection RubyMismatchedArgumentType
    controller_name(self)
  end

  # Derive the name of the model/controller from the given source.
  #
  # @param [Symbol, String, Class, nil] value
  #
  # @return [Symbol]
  #
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedReturnType
  #++
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
    __included(base, self)
    base.send(:extend,  self)
  end

end

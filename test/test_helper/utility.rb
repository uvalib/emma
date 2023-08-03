# test/test_helper/utility.rb
#
# frozen_string_literal: true
# warn_indent:           true

# General utility methods.
#
module TestHelper::Utility

  include TestHelper::Common

  # ===========================================================================
  # :section: Users
  # ===========================================================================

  public

  # The "/test/fixtures/users.yml" entry associated with the argument.
  #
  # @param [String, Symbol, *] arg
  #
  # @return [Symbol, nil]
  #
  def user_entry(arg)
    arg = arg.sub(/@.*$/, '').presence&.to_sym if arg.is_a?(String)
    # noinspection RubyMismatchedReturnType
    arg if arg.is_a?(Symbol) && (arg != :anonymous)
  end

  # Return a User instance from the given identification.
  #
  # @param [String, Symbol, User, *] user
  #
  # @return [User]
  # @return [nil]                     If *user* could not be converted.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def find_user(user)
    return                  if user == :anonymous
    user = user_entry(user) if user.is_a?(String)
    user = users(user)      if user.is_a?(Symbol)
    user                    if user.is_a?(User)
  end

  # Return multiple User instances.
  #
  # @param [Array] list               All users if empty.
  # @param [Hash]  matching           Limiting conditions if present.
  #
  # @return [Array<User,nil>]
  #
  def find_users(*list, **matching)
    anonymous = records = nil
    if list.present?
      list      = list.flatten
      original  = list.dup
      anonymous = list.reject! { |u| u.nil? || (u == :anonymous) }
      records   = list.reject! { |u| u.is_a?(User) }
      if list.present?
        list.map! { |u| user_entry(u) || u }
      elsif matching.blank?
        return original.map! { |u| u if u.is_a?(User) }
      end
    elsif matching.blank?
      return users
    end
    rec_ids = records&.map(&:id)
    added   = users(*list)
    added   = added.reject { |u| rec_ids.include?(u.id) } if rec_ids.present?
    records = [*records, *added]
    if matching.present?
      matching = ApplicationRecord.normalize_id_keys(matching)
      records.keep_if do |u|
        matching.all? do |k, v|
          if u[k].is_a?(Array) || v.is_a?(Array)
            Array.wrap(u[k]).intersect?(Array.wrap(v))
          else
            u[k] == v
          end
        end
      end
    end
    anonymous ? records.prepend(nil) : records
  end

  # ===========================================================================
  # :section: Fixtures
  # ===========================================================================

  public

  # The number of fixture records for the indicated model and constraints which
  # are associated with an organization.
  #
  # @param [Symbol, String, Class, ApplicationRecord] model
  # @param [Org, User, Integer, nil]                  org
  # @param [Hash]                                     constraints
  #
  # @return [Integer]
  #
  def fixture_count_for_org(model, org, **constraints)
    org = org.org_id if org.respond_to?(:org_id)
    if org.is_a?(Integer)
      fixture_count(model, **constraints) { |_, rec| rec.try(:org_id) == org }
    else
      fixture_count(model, **constraints)
    end
  end

  # The number of fixture records for the indicated model and constraints which
  # are associated with the given user.
  #
  # @param [Symbol, String, Class, ApplicationRecord] model
  # @param [User, Integer, nil]                       user
  # @param [Hash]                                     constraints
  #
  # @return [Integer]
  #
  def fixture_count_for_user(model, user, **constraints, &blk)
    user = user.user_id if user.respond_to?(:user_id)
    constraints.merge!(user_id: user) if user.is_a?(Integer)
    fixture_count(model, **constraints, &blk)
  end

  # The number of fixture records for the indicated model and constraints.
  #
  # @param [Symbol, String, Class, ApplicationRecord] model
  # @param [Hash]                                     constraints
  #
  # @return [Integer]
  #
  def fixture_count(model, **constraints, &blk)
    if blk || constraints.present?
      fixture_values(model, **constraints, &blk).size
    else
      fixtures_of(model).size
    end
  end

  # A table of fixture value Hashes for the indicated model type, optionally
  # matching the given constraints, which are associated with an organization.
  #
  # @param [Symbol, String, Class, ApplicationRecord] model
  # @param [Org, User, Integer, nil]                  org
  # @param [Hash]                                     constraints
  #
  # @return [Hash{Symbol=>Hash{Symbol=>*}}]
  #
  def fixture_values_for_org(model, org, **constraints)
    org = org.org_id if org.respond_to?(:org_id)
    if org.is_a?(Integer)
      fixture_values(model, **constraints) { |_, rec| rec.try(:org_id) == org }
    else
      fixture_values(model, **constraints)
    end
  end

  # A table of fixture value Hashes for the indicated model type, optionally
  # matching the given constraints, which are associated with the given user.
  #
  # @param [Symbol, String, Class, ApplicationRecord] model
  # @param [User, Integer, nil]                       user
  # @param [Hash]                                     constraints
  #
  # @return [Hash{Symbol=>Hash{Symbol=>*}}]
  #
  def fixture_values_for_user(model, user, **constraints, &blk)
    user = user.user_id if user.respond_to?(:user_id)
    constraints.merge!(user_id: user) if user.is_a?(Integer)
    fixture_values(model, **constraints, &blk)
  end

  # A table of fixture value Hashes for the indicated model type, optionally
  # matching the given constraints.
  #
  # @param [Symbol, String, Class, ApplicationRecord] model
  # @param [Hash]                                     constraints
  #
  # @return [Hash{Symbol=>Hash{Symbol=>*}}]
  #
  def fixture_values(model, **constraints)
    constraints =
      constraints.map { |k, v|
        if v.is_a?(ApplicationRecord)
          k = :"#{k}_id" unless k.end_with?('_id')
          v = v.id
        end
        [k, v]
      }.to_h
    fixtures_of(model)&.fixtures&.map { |key, rec|
      key = key.to_sym if key.is_a?(String)
      rec = rec.fixture.transform_keys(&:to_sym)
      use =
        constraints.all? do |k, v|
          if v.blank?
            rec[k].blank?
          else
            Array.wrap(rec[k]).intersect?(Array.wrap(v))
          end
        end
      # noinspection RubyMismatchedArgumentType
      use &&= yield(key, rec) if block_given?
      [key, rec] if use
    }&.compact&.to_h || {}
  end

  # Fixture set for the indicated model type.
  #
  # @param [Symbol, String, Class, ApplicationRecord] model
  #
  # @return [ActiveRecord::FixtureSet, nil]
  #
  def fixtures_of(model)
    name = controller_name(model).to_s.pluralize
    @loaded_fixtures[name]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
    if item.is_a?(SearchResult)
      repo   ||= item.repository
      rid    ||= item.repositoryRecordId
      format ||= item.format
      ver    ||= item.formatVersion
    end
    [repo, rid, format].compact_blank!.tap { |parts|
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
  # @param [Array, Symbol, nil] only  Applicable format(s) or :all; default:
  #                                     #TEST_FORMATS.
  #
  # @return [true]                    If the test should proceed.
  # @return [false]                   If the test should be skipped.
  #
  def allowed_format(fmt = nil, note = nil, only:)
    fmt, note = [nil, fmt] if fmt.is_a?(String)
    only = Array.wrap(only).compact
    only = TEST_FORMATS if only.blank? || only.include?(:all)
    return true if fmt.nil? && Array.wrap(only).intersect?(TEST_FORMATS)
    return true if Array.wrap(only).intersect?(Array.wrap(fmt))
    format = 'format'
    only   = only.first if only.is_a?(Array) && !only.many?
    msg    = ['TEST SKIPPED']

    if fmt.nil?
      format = format.pluralize if only.is_a?(Array)
      msg << "ONLY APPLICABLE for #{only.inspect} #{format}"

    elsif only.is_a?(Array)
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

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

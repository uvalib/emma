# test/test_helper/utility.rb
#
# frozen_string_literal: true
# warn_indent:           true

# General utility methods.
#
module TestHelper::Utility

  include TestHelper::Common
  include TestHelper::Debugging

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  RUN_TEST_OPT = %i[test part frame only meth].freeze

  # Run the test code provided via the block.
  #
  # When debugging, this frames the console output generated by the test.
  #
  # @param [String, Symbol, nil] test_name
  # @param [Symbol, nil]         format
  # @param [Array, Symbol, nil]  only
  # @param [Integer, nil]        wait
  # @param [Hash]                opt        Passed to #show_test_start and
  #                                           #show_test_end.
  # @param [Proc]                block      Required.
  #
  # @return [void]
  #
  # @yield The test code to be run
  # @yieldreturn [void]
  #
  def run_test(test_name, format: nil, only: nil, wait: nil, **opt, &block)
    error = nil
    prime_tests
    if format && !html?(format)
      opt[:part] = ["[#{format.to_s.upcase}]", opt[:part]].compact.join(' - ')
    end
    show_test_start(test_name, **opt)
    if allowed_format(format, only: only)
      if wait
        using_wait_time(wait, &block)
      else
        block.call
      end
    end
  rescue Exception => error
    show "[#{error.class}: #{error}]"
  ensure
    show_test_end(test_name, **opt)
    # noinspection RubyMismatchedArgumentType
    raise error if error
  end

  # Make sure that "Sign in as" is visible on the sign-in page by ensuring that
  # the interface is in "debug mode".
  #
  # This also initializes `request.referrer` to a known good page so that
  # `redirect :back` will always work without need for a fallback location
  # (which may or may not be appropriate).
  #
  # @return [void]
  #
  def prime_tests
    meth = %i[visit get].find { |m| respond_to?(m) } or return
    without_tracing do
      # Since the option causes a redirect, it's a little faster to avoid it
      # for subsequent executions.
      opt = self.tests_primed ? {} : { debug: true }
      send(meth, root_url(**opt))
      self.tests_primed = true
    end
  end

  # @private
  # @type [Boolean, nil]
  attr_accessor :tests_primed
  protected :tests_primed

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # For controller tests to covering the differences between authenticated and
  # non-authenticated sessions.
  #
  # @type [Array<Symbol>]
  #
  CORE_TEST_USERS = %i[anonymous test_dso_1].freeze

  # For controller tests to covering varying behaviors depending on the role
  # of the user session.
  #
  # @type [Array<Symbol>]
  #
  ALL_TEST_USERS =
    %i[anonymous test_guest_1 test_dso_1 test_man_1 test_adm].freeze

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
    user = user_entry(user) if user.is_a?(String)
    case user
      when :anonymous then nil
      when User       then user
      when Symbol     then users(user)
      when Integer    then User.find(user)
    end
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
    added   = Array.wrap(users(*list))
    added   = added.reject { |u| rec_ids.include?(u.id) } if rec_ids.present?
    records = [*records, *added]
    if matching.present?
      matching = ApplicationRecord.normalize_id_keys(matching)
      records.keep_if do |u|
        matching.all? do |k, v|
          u_value = u.respond_to?(k) ? u.send(k) : u[k]
          if u_value.is_a?(Array) || v.is_a?(Array)
            Array.wrap(u_value).intersect?(Array.wrap(v))
          else
            u_value == v
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

  # Extract the User ID indicated by *item*.
  #
  # @param [*] item
  #
  # @return [Integer, nil]
  #
  def uid(item)
    user_id = ->(rec) { rec[:user_id] || rec.try(:user_id) }
    # noinspection RailsParamDefResolve
    user =
      case item
        when User    then item
        when Integer then item
        when Symbol  then users(item)
        when Hash    then item.values_at(:user_id, :user).first
        when Model   then user_id.(item) || item.try(:user)
      end
    case user
      when User    then user.id
      when Model   then user_id.(user)
      when Integer then positive(user)
    end
  end

  # Extract the Organization ID indicated by *item*.
  #
  # @param [*] item
  #
  # @return [Integer, nil]
  #
  def oid(item)
    return if item.nil?
    org_id = ->(rec) { rec[:org_id] || rec.try(:org_id) }
    # noinspection RailsParamDefResolve
    org =
      case item
        when Org     then item
        when User    then item
        when Integer then item
        when Symbol  then orgs(item)
        when Hash    then item.values_at(:org_id, :org).first
        when Model   then org_id.(item) || item.try(:org)
      end
    org ||= find_user(uid(item))
    # noinspection RubyMismatchedReturnType
    case org
      when Org     then org.id
      when Model   then org_id.(org)
      when Integer then positive(org)
    end
  end

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
    if (org = oid(org))
      fixture_count(model, **constraints) { |_, rec| oid(rec) == org }
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
  def fixture_count_for_user(model, user, **constraints)
    user = uid(user) and constraints.merge!(user_id: user)
    fixture_count(model, **constraints)
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
    if (org = oid(org))
      fixture_values(model, **constraints) { |_, rec| oid(rec) == org }
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
  def fixture_values_for_user(model, user, **constraints)
    user = uid(user) and constraints.merge!(user_id: user)
    fixture_values(model, **constraints)
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

  public

  # Option keys for sending requests which are not URL parameters.
  #
  # @type [Array<Symbol>]
  #
  REQUEST_OPT = %i[controller action format].freeze

  # Option keys supporting test methods which are not URL parameters.
  #
  # @type [Array<Symbol>]
  #
  TEST_OPT = [:expect, *RUN_TEST_OPT].freeze

  # Option keys which are not URL parameters.
  #
  # @type [Array<Symbol>]
  #
  NON_URL_PARAMETER_KEYS = [*REQUEST_OPT, *TEST_OPT].uniq.freeze

  # For controllers whose "/index" action is actually a redirect to one or more
  # possible list actions.
  #
  # @param [Symbol, String, Proc, nil] dst
  # @param [String, Symbol, User, *]   user
  # @param [Hash]                      opt
  #
  # @return [String]                  The redirection path.
  # @return [nil]                     If *opt* includes search terms.
  #
  def index_redirect(dst: nil, user: nil, **opt)
    return if opt.except(*NON_URL_PARAMETER_KEYS).present?
    ctrlr = opt[:controller]
    user  = find_user(user || current_user)
    dst   = yield      if block_given?
    dst   = dst.call   if dst.is_a?(Proc)
    dst   = dst.to_sym if dst.is_a?(String)
    dst ||= (:list_all if user&.administrator?)
    dst ||= (:list_org if user&.manager?)
    dst ||=  :list_own
    "/#{ctrlr}/#{dst}"
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

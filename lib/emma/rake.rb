# lib/emma/rake.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'rake'
require 'rake/dsl_definition'

require 'emma'

__loading_begin(__FILE__)

# Rake support methods.
#
# == Usage Notes
# This is designed so that "require 'emma/rake'" will set up definitions in the
# *.rake file in one step.  Loading this file in any other context is untested
# and probably not a good idea.
#
module Emma::Rake

  include Emma::Common
  include Emma::TimeMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # True for "rake --quiet" or when not running from the command line.
  #
  # @type [Boolean]
  #
  QUIET_DEFAULT = false?(Rake.verbose) || !$stdin.tty?

  # True for "rake --verbose" or when running from the command line unless
  # "rake --quiet".
  #
  # @type [Boolean]
  #
  VERBOSE_DEFAULT = $stdin.tty? ? !false?(Rake.verbose) : true?(Rake.verbose)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Run a Rake task from within a task definition.
  #
  # @param [String, Symbol]                        name
  # @param [Hash, Array, Rake::TaskArguments, nil] args
  #
  # @return [void]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def subtask(name, args = nil)
    hash =
      case args
        when Hash  then args
        when Array then args.map { |a| a.split('=', 2) }.to_h.symbolize_keys
        else            args&.to_hash || {}
      end
    hash.transform_values!(&:to_s).compact_blank!
    unless args.is_a?(Rake::TaskArguments)
      args = Rake::TaskArguments.new(hash.keys, hash.values)
    end

    quiet = true?(hash[:quiet]) || false?(hash[:verbose])

    # @type [Rake::Task]
    task = Rake::Task[name.to_s]
    show "\nRunning '#{task.name}'..." unless quiet
    task.execute(args)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # task_options
  #
  # @param [Array<String,Symbol>] flags
  #
  # @return [Array<String,nil>]
  #
  def task_options(*flags)
    flags, args = flags.partition { |f| f.is_a?(String) || f.is_a?(Symbol) }
    flags.map { |flag| task_option(flag, args) }
  end

  # Indicate whether the option flag was provided via task arguments or on the
  # the command line (after "--").
  #
  # @param [String, Symbol]                  flag
  # @param [Rake::TaskArguments, Array, nil] task_args
  #
  def task_option?(flag, task_args = nil)
    value = task_option(flag, task_args)
    !value.nil? && !value.casecmp?('false')
  end

  # Return the value of an option flag provided via task arguments or on the
  # the command line (after "--").
  #
  # A flag of the form "--name" will return "" if present.
  # A flag of the form "--name=value" will return *value* if present.
  #
  # @param [String, Symbol]                  flag
  # @param [Rake::TaskArguments, Array, nil] args   From task arguments.
  #
  # @return [String, nil]
  #
  def task_option(flag, args = nil)
    flag = %W(--#{flag} -#{flag} #{flag})
    # noinspection RubyMismatchedReturnType
    [args, cli_task_options].compact_blank!.find do |options|
      options.find do |opt|
        opt, val = opt.is_a?(Array) ? opt.map(&:to_s) : opt.split('=', 2)
        return val || '' if flag.include?(opt)
      end
    end
  end

  # Option flags on the "rake" command line after "--" will be ignored by Rake
  # but will be available in $*.
  #
  # @return [Array<String>]
  #
  def cli_task_options
    @cli_task_options ||= (start = $*.index('--')) ? $*[(start+1)..] : []
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A time span message.
  #
  # @param [Float] start_time         Default: time now.
  #
  # @return [Float]
  #
  def save_start_time(start_time = nil)
    @start_time = start_time || timestamp
  end

  # A time span message.
  #
  # @param [Float] start_time         Default: @start_time.
  #
  # @return [String]
  #
  def elapsed_time(start_time = nil)
    '[Run time %s]' % time_span(start_time || @start_time)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Send line(s) to output.
  #
  # @param [Array<String, Array, nil>] lines
  # @param [IO]                        io
  #
  # @return [nil]
  #
  def show(*lines, io: $stdout)
    lines.flatten!
    lines.compact!
    io.puts lines.join("\n")
  end

  # ===========================================================================
  # :section: Rails mocks
  # ===========================================================================

  public

  # An override to provide a mock #session.
  #
  # @return [Hash{String=>Any}]
  #
  def session
    @session ||= { 'app.debug' => true }
  end

  # An override to provide a mock #current_user.
  #
  # @return [User, nil]
  #
  # @note Needs to be a user mapped to the developer role in 'users_roles'.
  #
  def current_user
    # noinspection RubyMismatchedReturnType
    @current_user ||=
      begin
        User.where(email: 'rwl@virginia.edu').first
      rescue
        # No database for "rake assets:precompile" in Dockerfile, so default
        # to setting up a fake user in a way that the database will not be
        # accessed.
        Struct.new(:id, :email) {
          def developer?;     true; end
          def administrator?; true; end
        }.new(1, 'fake@virginia.edu')
      end
  end

  # ===========================================================================
  # :section: Rake overrides
  # ===========================================================================

  public

  module DSL

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include Rake::DSL
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Override Rake::DSL#desc for multi-line descriptions.
    # (Only the first is visible with "rake -T".)
    #
    # @param [Array<String, Array>] line
    #
    def desc(*line)
      super line.flatten.join("\n")
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.send(:extend, self)
  end

end

# =============================================================================
# Override Rake definitions.
# =============================================================================

extend Emma::Rake::DSL
include Emma::Rake

__loading_end(__FILE__)

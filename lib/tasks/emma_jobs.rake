# lib/tasks/emma_jobs.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# Maintenance tasks for database table(s) involved with EMMA jobs.

require 'emma/rake'

# =============================================================================
# Tasks
# =============================================================================

namespace 'emma:jobs' do

  # ===========================================================================

  namespace :unfinished do

    # desc 'List unfinished counts by default'
    task list: :counts

    desc 'List counts of unfinished records for each table'
    task counts: :prerequisites do
      record_classes.each do |table|
        list_count(table, table.incomplete_count)
      end
    end

    desc 'List tables with unfinished jobs'
    task tables: :prerequisites do
      record_classes.each do |table|
        (count = positive(table.incomplete_count)) and list_count(table, count)
      end
    end

    desc 'List records of unfinished jobs'
    task records: :prerequisites do
      record_classes.each do |table|
        list_records(table, table.incomplete_list) do |record|
          prm = record.serialized_params&.deep_symbolize_keys || {}
          req = prm[:arguments]&.at(1)&.dig(:value, :request)
          req = req&.reject { |k,_| k.start_with?('_') }&.presence || '-'
          [req, record.performed_at, record.id]
        end
      end
    end

    desc 'Remove records of unfinished jobs'
    task clean: :prerequisites do
      record_classes.each do |table|
        delete_records(table, table.incomplete_count, :incomplete_delete)
      end
    end

  end

  # ===========================================================================

  namespace :outdated do

    WARNING ||= [ # TODO: persist last boot time of application
      'NOTE: Mechanism required to persist last boot time of application.',
      '(Results are relative to BOOT_TIME for this rake task.)'
    ].freeze

    # desc 'List outdated counts by default'
    task list: :counts

    desc 'List counts of records unchanged since the last reboot'
    task counts: :prerequisites do
      WARNING.each { |line| $stderr.puts line }
      record_classes.each do |table|
        list_count(table, table.outdated_count)
      end
    end

    desc 'List tables unchanged since the last reboot'
    task tables: :prerequisites do
      WARNING.each { |line| $stderr.puts line }
      record_classes.each do |table|
        (count = positive(table.outdated_count)) and list_count(table, count)
      end
    end

    desc 'List records unchanged since the last reboot'
    task records: :prerequisites do
      WARNING.each { |line| $stderr.puts line }
      record_classes.each do |table|
        list_records(table, table.outdated_list)
      end
    end

    desc 'Remove records from select databases unchanged since the last reboot'
    task clean: :prerequisites do
      WARNING.each { |line| $stderr.puts line }
      record_classes.each do |table|
        delete_records(table, table.outdated_count, :outdated_delete)
      end
    end

  end

  # ===========================================================================

  # desc 'Required prerequisites for tasks in this namespace.'
  task prerequisites: 'emma:model:prerequisites'

  # ===========================================================================
  # Methods
  # ===========================================================================

  public

  # All ActiveRecord classes that respond to :outdated.
  #
  # @return [Array<Class>]
  #
  def record_classes(c = ActiveRecord::Base)
    # noinspection SpellCheckingInspection
    return []  if c.name.nil? || c.name.start_with?('HABTM_')
    return [c] if c.ancestors.include?(JobMethods)
    c.subclasses.flat_map { |sc| record_classes(sc) }.compact
  end

  # list_count
  #
  # @param [Class]   table
  # @param [Integer] count
  #
  def list_count(table, count)
    $stdout.puts "#{count}\t#{table.name}"
  end

  # list_records
  #
  # @param [Class]                  table
  # @param [ActiveRecord::Relation] list
  # @param [Proc]                   blk     Applied to each record
  #
  def list_records(table, list, &blk)
    list   = (blk ? list&.map(&blk) : list&.dup).presence
    list &&= list.map! { |rec| Array.wrap(rec.try(:fields) || rec).join("\t") }
    list ||= %w[NONE]
    $stdout.puts list.map! { |item| "#{table.name} - #{item}" }
  end

  # delete_records
  #
  # @param [Class]   table
  # @param [Integer] count            Number of records to be deleted.
  # @param [Symbol]  meth             Method on *table*.
  #
  def delete_records(table, count, meth)
    return unless positive(count)
    result = table.try(meth)
    if result == count
      result = "#{result} records deleted"
    elsif result
      result = "response: #{result}"
    else
      result = "unchanged: no :#{meth} defined"
    end
    $stdout.puts "#{table.name} - #{result}"
  end

end

# desc 'An alias for "rake emma:jobs:unfinished:list".'
task 'emma:unfinished' => 'emma:jobs:unfinished:list'

# desc 'An alias for "rake emma:jobs:outdated:list".'
task 'emma:outdated' => 'emma:jobs:outdated:list'

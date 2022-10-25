# config/initializers/_extensions.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions to classes that need to be established as soon as possible during
# initialization.

Rails.logger.progname = '____' if Rails.logger && Rails.logger.progname.blank?

# == Loader debugging
Rails.autoloaders.main.log! if DEBUG_ZEITWERK

# == Threads debugging
Concurrent.use_simple_logger(Logger::DEBUG) if DEBUG_THREADS

# == JSON optimization
require 'oj'
# noinspection RubyResolve -- Allow Oj to override JSON methods.
Oj.optimize_rails

# == Local definitions and gem extensions/overrides
require 'pp'
require Rails.root.join('lib/emma').to_path

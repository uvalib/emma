# config/initializers/_extensions.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions to classes that need to be established as soon as possible during
# initialization.

# == Loader debugging
Rails.autoloaders.main.log! if true?(ENV['DEBUG_ZEITWERK'])

# == JSON optimization
require 'oj'
# noinspection RubyResolve -- Allow Oj to override JSON methods.
Oj.optimize_rails

# == Local definitions and gem extensions/overrides
require 'pp'
require Rails.root.join('lib/emma').to_path

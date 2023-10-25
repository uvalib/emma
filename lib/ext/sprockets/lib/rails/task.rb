# lib/ext/sprockets/lib/rails/task.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Sprockets gem overrides.

__loading_begin(__FILE__)

require 'sprockets/rails'
require 'sprockets/rails/task'

module Sprockets

  module Rails

    module TaskExt

      # Redefine @logger to be an Emma::Logger.
      #
      # @param [Rails::Application, nil] app
      #
      def initialize(app = nil)
        super
        @logger = Sprockets.local_logger(@logger, progname: 'SPROCKETS TASK')
      end

    end

  end

end

override Sprockets::Rails::Task => Sprockets::Rails::TaskExt

__loading_end(__FILE__)

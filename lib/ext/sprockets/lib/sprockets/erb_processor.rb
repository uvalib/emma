# lib/ext/sprockets/lib/sprockets/sassc_processor.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Corrects a problem with Sprockets 4.0.2 when run with Ruby 3+.

__loading_begin(__FILE__)

if false # if RUBY_VERSION >= '3'

  require 'sprockets/erb_processor'

  module Sprockets::ERBProcessorExt

    include Sprockets::ExtensionDebugging

    def call(input)
      __ext_log("ERBProcessor override [#{self}]")

      engine = ::ERB.new(input[:data], trim_mode: '<>')
      engine.filename = input[:filename]

      context = input[:environment].context_class.new(input)
      klass = (class << context; self; end)
      klass.const_set(:ENV, context.env_proxy)
      klass.class_eval(&@block) if @block

      data = engine.result(context.instance_eval('binding'))
      context.metadata.merge(data: data)
    end

  end

  override Sprockets::ERBProcessor => Sprockets::ERBProcessorExt

end

__loading_end(__FILE__)

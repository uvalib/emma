# app/helpers/decorator_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting the generation of decorators.
#
module DecoratorHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate context values for inclusion in the parameters to a decorator
  # constructor.
  #
  # @param [Symbol, String, nil] action
  # @param [Hash]                opt
  #
  # @return [Hash]
  #
  def context(action = nil, **opt)
    action             ||= opt[:action] || params[:action]
    opt[:sub_topic]    ||= action.to_sym
    opt[:action]       ||= action.to_s.delete_suffix('_current').to_sym
    opt[:cancel]       ||= params[:cancel] if params[:cancel]
    opt[:user]         ||= current_user    if defined?(current_user)
    opt[:request]      ||= request         if defined?(request)
    opt[:paginator]    ||= paginator       if defined?(paginator)
    opt[:options]      ||= @model_options  if defined?(@model_options)
    opt[:group_counts] ||= @group_counts   if defined?(@group_counts)
    opt[:results_type] ||= results_type    if defined?(results_type)
    opt[:search_style] ||= search_style    if defined?(search_style)
    opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)

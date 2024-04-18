# app/mailers/application_mailer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class ApplicationMailer < ActionMailer::Base

  include Emma::Common
  include HtmlHelper

  # @private
  MAIL_OPT = %i[to from subject cc bcc].freeze

  # ===========================================================================
  # :section: Mailer layout
  # ===========================================================================

  helper LayoutHelper::PageLanguage

  layout 'mailer'

  # ===========================================================================
  # :section: Mailer settings
  # ===========================================================================

  default from: MAILER_SENDER

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Transform *body* into an array of paragraphs.
  #
  # @param [Array, String]       body
  # @param [Symbol, String, nil] format
  # @param [Integer, nil]        width
  # @param [String]              paragraph
  #
  # @return [Array<ActiveSupport::SafeBuffer>]    If *format* == :html
  # @return [Array<String>]                       Otherwise
  #
  def format_paragraphs(body, format: nil, width: 80, paragraph: "\n\n", **)
    body = body.is_a?(Array) ? body.flatten : [body]
    if format&.to_sym == :html
      body.flat_map do |v|
        if !v.is_a?(String)
          html_paragraph(v.to_s)
        elsif v.html_safe?
          v.split(paragraph).map(&:html_safe)
        else
          v.split(paragraph).map { |p| html_paragraph(p) }
        end
      end
    else
      width = positive(width)
      body.flat_map { |v|
        if !v.is_a?(String)
          v.to_s
        elsif v.html_safe?
          sanitized_string(v).split(paragraph)
        else
          v.split(paragraph)
        end
      }.tap { |parts| parts.map! { |v| wrap_lines(v, width: width) } if width }
    end
  end

  # Replace white space in *text* to yield a result containing one or more
  # newline-delimited lines.
  #
  # @param [String]  text
  # @param [Integer] width
  #
  # @return [String]
  #
  def wrap_lines(text, width: 80)
    line, n = [+''], 0
    text.to_s.scan(/([^\s]+)(\s+|$)/) do |v, _|
      if (line[n].size + v.size) > width
        n = n.succ
        line[n] = +''
      end
      line[n] << "#{v} "
    end
    line.map!(&:rstrip).join("\n")
  end

end

__loading_end(__FILE__)

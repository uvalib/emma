# app/models/manifest_item/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::Assignable

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::Assignable
    include Record::InstanceMethods
    # :nocov:
  end

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Ensure that blanks are allowed and that input values are normalized.
  #
  # @param [Hash, nil] attr
  # @param [Hash, nil] opt
  #
  # @return [Hash{Symbol=>Any}]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def attribute_options(attr, opt = nil)
    return {} if attr.blank?
    opt  = { compact: false }.merge!(opt || {})
    warn = ->(msg) { Log.warn { "#{__method__}: #{msg}" }; true }
    hash = {}
    attr.each_pair do |k, v|
      k = k.to_s.delete_suffix('[]').to_sym if k.end_with?('[]')
      next unless (config = database_columns[k])
      warn.("replacing #{hash[k].inspect} with #{v.inspect}") if hash.key?(k)
      if v.nil?
        # Same for all field types regardless.
      elsif config.array
        v = v.compact_blank                 if v.is_a?(Array)
        v = v.split("\n").compact_blank!    if v.is_a?(String)
        warn.("type #{v.class} unexpected") unless v.is_a?(Array)
        v = Array.wrap(v).presence
      elsif %i[json jsonb].include?(config.type)
        if v.is_a?(String)
          v = json_parse(v)
        elsif v.is_a?(Array)
          v = v.flat_map { |h| json_parse(h) }.compact
        elsif !v.is_a?(Hash)
          warn.("type #{v.class} unexpected; ignored #{v.inspect}") and next
        end
      else
        v = v.compact.join(";\n") if v.is_a?(Array)
      end
      hash[k] = v
    end
    super(hash, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)

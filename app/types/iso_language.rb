# app/types/iso_language.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ISO 639-2 alpha-3 language code.
#
class IsoLanguage < ScalarType

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include ScalarType::Methods

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [any, nil] v             String
    #
    def valid?(v)
      v = normalize(v)
      ISO_639.find_by_code(v).present?
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v             String
    #
    # @return [String]
    #
    def normalize(v)
      v = super
      code(v) || v
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Return the associated three-letter language code.
    #
    # @param [any, nil] value         String
    #
    # @return [String, nil]
    #
    def code(value)
      find(value)&.alpha3
    end

    # Find a matching language entry.
    #
    # @param [any, nil] value         String
    #
    # @return [ISO_639, nil]
    #
    def find(value)
      # @type [Array<ISO_639>] entries
      entries = ISO_639.search(value = value.to_s.strip.downcase)
      if entries.size <= 1
        entries.first
      else
        # @type [ISO_639] entry
        entries.find do |entry|
          (value == entry.alpha3) ||
            entry.english_name.downcase.split(/\s*;\s*/).any? do |part|
              value == part.strip
            end
        end
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include Methods

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Assign a new value to the instance.
  #
  # @param [any, nil] v
  # @param [Hash]     opt             Passed to ScalarType#set
  #
  # @return [String, nil]
  #
  def set(v, **opt)
    opt.reverse_merge!(warn: true)
    super
  end

  # ===========================================================================
  # :section: IsoLanguage::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance is valid.
  #
  # @param [any, nil] v               Default: #value.
  #
  def valid?(v = nil)
    v ||= value
    super
  end

  # Return the associated three-letter language code.
  #
  # @param [any, nil] v               Default: #value.
  #
  # @return [String, nil]
  #
  def code(v = nil)
    v ||= value
    super
  end

end

__loading_end(__FILE__)

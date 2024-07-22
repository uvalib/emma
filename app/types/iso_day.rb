# app/types/iso_day.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ISO 8601 day.
#
class IsoDay < IsoDate

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include IsoDate::Methods

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [any, nil] v
    #
    def valid?(v)
      day?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v             String, Date, Time, IsoDate
    #
    # @return [String, nil]
    #
    def normalize(v)
      v = clean(v)
      return v.value         if v.is_a?(self_class)
      v = strip_copyright(v) if v.is_a?(String)
      day_convert(v)
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
  # :section: IsoDay::Methods overrides
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

end

__loading_end(__FILE__)

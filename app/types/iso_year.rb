# app/types/iso_year.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ISO 8601 year.
#
class IsoYear < IsoDate

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

    # Indicate whether `*v*` would be a valid value for an item of this type.
    #
    # @param [any, nil] v
    #
    def valid?(v)
      year?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String, nil]
    #
    def normalize(v)
      v = clean(v)
      return v.value         if v.is_a?(self_class)
      v = strip_copyright(v) if v.is_a?(String)
      year_convert(v)
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
  # :section: IsoYear::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance is valid.
  #
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    v ||= value
    super
  end

end

__loading_end(__FILE__)

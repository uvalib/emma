# app/types/doi.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# DOI identifier.
#
# - UTF-8 Unicode characters
# - Case-insensitive for ASCII Unicode characters
# - Case-sensitive for non-ASCII Unicode characters
#
# @see https://www.doi.org/doi_handbook/2_Numbering.html
#
class Doi < PublicationIdentifier

  PREFIX = name.underscore
  TYPE   = PREFIX.to_sym

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include PublicationIdentifier::Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A pattern matching any of the expected DOI prefixes.
    #
    # @type [Regexp]
    #
    DOI_PREFIX = %r{^\s*(
      doi(:\s*|\s+) |
      (https?:)?(//)?doi\.org/ |
      (https?:)?(//)?dx\.doi\.org/
    )}ix.freeze

    # A pattern matching the form of an DOI identifier.
    #
    # @type [Regexp]
    #
    DOI_IDENTIFIER = /^10\.\d{4,}(\.d+)*\/.*$/.freeze

    # A pattern matching the form of a (possibly invalid) DOI identifier.
    #
    # @type [Regexp]
    #
    DOI_CANDIDATE = /^10\.\d/.freeze

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [any, nil] v
    #
    def valid?(v)
      doi?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      remove_prefix(v).rstrip
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the given value appears to include a DOI.
    #
    # @param [any, nil] v
    #
    # === Usage Notes
    # If *v* matches #DOI_PREFIX then the method returns *true* even if the
    # actual number is invalid; the caller is expected to differentiate between
    # valid and invalid cases and handle each appropriately.
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(DOI_PREFIX, '').present? || v.match?(DOI_CANDIDATE)
    end

    # Extract the base identifier of a possible DOI.
    #
    # @param [any, nil] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(DOI_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    # === Implementation Notes
    # Accounts for not-quite-valid forms like "doi:https://doi.org/..." by
    # repeating prefix removal.
    #
    def remove_prefix(v)
      v.to_s.sub(DOI_PREFIX, '').sub(DOI_PREFIX, '')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the value is a valid DOI.
    #
    # @param [any, nil] v
    #
    def doi?(v)
      to_doi(v, log: false).present?
    end

    # If the value is a DOI return it in a normalized form or *nil* otherwise.
    #
    # @param [any, nil] v
    # @param [Boolean]  log
    #
    # @return [String, nil]
    #
    def to_doi(v, log: true, **)
      doi = identifier(v) and return doi
      Log.info { "#{__method__}: #{v.inspect} is not a valid DOI" } if log
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
  # :section: PublicationIdentifier::Methods overrides
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

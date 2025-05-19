# lib/_configuration.rb
#
# frozen_string_literal: true
# warn_indent:           true

require '_system'
require '_trace'

__loading_begin(__FILE__)

# General access into "config/locales/**.yml" configuration information.
#
module Configuration

  include SystemExtension

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The root of all I18n paths related to the project.
  #
  # @note Does not include locale.
  #
  # @type [String]
  #
  CONFIG_ROOT = 'emma'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All "en.emma.*" configuration values.
  #
  class Data

    include Singleton

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # All "en.emma.*" configuration values.
    #
    # @return [Hash]                    Deep-frozen.
    #
    def self.all = instance.all

    # All "en.emma.*" configuration values.
    #
    # @return [Hash]                    Deep-frozen.
    #
    def all = @all ||= fetch_all || fetch_all(initialize: true)

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Acquire "en.emma.*" configuration values.
    #
    # @return [Hash]                    Deep-frozen.
    # @return [nil]                     Failed to find "en.(CONFIG_ROOT)".
    #
    def fetch_all(initialize: false)
      if initialize
        require 'active_support/i18n'
        require 'active_support/i18n_railtie'
        I18n.load_path +=
          Dir[Rails.root.join('config/locales/**/*.{rb,yml}').to_s]
        I18n.load_path.uniq!
        I18n::Railtie.initialize_i18n(Rails.application)
      end
      process(I18n.t(CONFIG_ROOT, default: nil))
    end

    # Recursively process a portion of a configuration hierarchy, in particular
    # ensuring that the values for '*_html' keys are made HTML-safe.
    #
    # @param [any, nil]     item
    # @param [Boolean, nil] html
    #
    # @return [any, nil]
    #
    def process(item, html = nil)
      if item.is_a?(Hash)
        item = item.map { |k, v|
          h = (k.end_with?('_html') if k.is_a?(String) || k.is_a?(Symbol))
          v = process(v, h)
          [k, v]
        }.to_h
      elsif item.is_a?(String)
        item = item.html_safe if html && !item.html_safe?
      end
      item.freeze
    end

  end

  # All "en.emma.*" configuration values.
  #
  # @return [Hash]                    Deep-frozen.
  #
  def config_all
    Configuration::Data.all
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Appropriately-typed configuration values taken from `ENV`,
  # `Rails.application.credentials`, or "en.emma.env_var" YAML configuration.
  #
  class EnvVar < ::Hash

    include Singleton

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Create an instance which combines configuration values from sources in
    # this order of precedence:
    #
    # 1. From `ENV`.
    # 2. From `Rails.application.credentials`.
    # 3. From YAML configuration ("en.emma.env_var").
    #
    # As a side effect, values missing from `ENV` will be updated with values
    # from the other sources.
    #
    # @param [Boolean] update_env     If *false*, do not modify `ENV`.
    # @param [Boolean] check_env      If *true*, run #validate.
    #
    def initialize(update_env: true, check_env: sanity_check?)
      env, cred, yaml = from_env, from_credentials, from_yaml
      [*env.keys, *cred.keys, *yaml.keys].sort.uniq.map do |key|
        val = env_value(env[key]).freeze
        val = cred[key] if val.nil?
        val = yaml[key] if val.nil?
        self[key] = val unless val.nil?
      end
      if (update_env &&= keys - ENV.keys).present?
        slice(*update_env).each_pair do |key, val|
          ENV[key] = val.is_a?(String) ? val : val.to_json.freeze
        end
      end
      validate if check_env
    end

    # Compare the configuration values stored in `ENV` with the configuration
    # values stored here.
    #
    # @param [Boolean] output         If *false*, just return error messages.
    # @param [Boolean] fatal          If *true*, raise exception on mismatch.
    # @param [String]  prefix         Error message prefix.
    #
    # @return [Array<String>]         Error messages.
    #
    def validate(output: true, fatal: false, prefix: 'CONFIG MISMATCH', **)
      warnings =
        from_credentials.map { |k, c|
          next if (v = self[k]) == c
          v = v.inspect
          c = c.inspect
          "#{prefix} #{k} | ENV_VAR = #{v} | credentials = #{c}"
        }.compact
      errors =
        map { |k, v|
          v = env_value(v)
          e = env_value(ENV[k])
          next if v == e
          v = "#{v.class} #{v.inspect}"
          e = "#{e.class} #{e.inspect}"
          "#{prefix} #{k} | ENV_VAR = #{v} | ENV = #{e}"
        }.compact
      warnings.each { __output(_1) }  if output
      errors.each { __output(_1) }    if output
      raise prefix                    if fatal && errors.present?
      warnings + errors
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Original configuration entries from `ENV`.
    #
    # @return [Hash{String=>String}]  Frozen results.
    #
    def from_env
      @from_env ||= get_env.transform_values(&:freeze).freeze
    end

    # Configuration entries from "en.emma.env_var".
    #
    # @return [Hash{String=>any}]     Frozen results.
    #
    def from_yaml
      @from_yaml ||= get_yaml.transform_values(&:freeze).freeze
    end

    # Configuration values from `Rails.application.credentials`.
    #
    # @return [Hash{String=>any}]     Frozen results.
    #
    def from_credentials
      @from_credentials ||= get_credentials.transform_values(&:freeze).freeze
    end

    # All environment variable names whether or not they have a value.
    #
    # @return [Array<String>]
    #
    def known_keys
      [from_env, from_credentials, from_yaml].flat_map(&:keys).sort.uniq
    end

    # Parse an entry from `ENV` into a typed value.
    #
    # @param [any] value
    #
    # @return [any]
    #
    def env_value(value)
      return try(value) || Object.try(value) || value if value.is_a?(Symbol)
      return value unless value.is_a?(String)
      value = value.strip.sub(/^"(.*)"$/, '\1')
      if value.start_with?('(?')
        regexp(value) || value
      elsif value.start_with?('{')
        JSON.parse(value, symbolize_names: true) rescue value
      elsif value.sub!(/^\[(.*)\]$/, '\1')
        value.split(/[;,|\t\n]/).map! { env_value(_1) }.compact_blank
      elsif value.present?
        case value.downcase
          when *TRUE_VALUES                                   then true
          when *FALSE_VALUES                                  then false
          when /^[-+]?\d+(_\d+)*$/                            then value.to_i
          when /^[-+]?\.0+(_0+)*$/                            then value.to_f
          when /^[-+]?0+(_0+)*\.0*$/                          then value.to_f
          when /^[-+]?\.\d+(_\d+)*(e[-+]?\d+)?$/              then value.to_f
          when /^[-+]?\d+(_\d+)*\.(\d+(_\d+)*)?(e[-+]?\d+)?$/ then value.to_f
          else                                                     value
        end
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Keys within a credentials group for AWS values mapped on to environment
    # variable names.
    #
    # @type [Hash{Symbol=>String}]
    #
    AWS_KEYS = {
      bucket:             'AWS_BUCKET',
      region:             'AWS_REGION',
      access_key_id:      'AWS_ACCESS_KEY_ID',
      secret_access_key:  'AWS_SECRET_KEY',
    }.freeze

    # Keys that may be included in `Rails.application.credentials.s3` mapped to
    # environment variable names.
    #
    # @type [Hash{Symbol=>String}]
    #
    S3_KEY_ENV = AWS_KEYS.freeze

    # Keys that may be included in `Rails.application.credentials.bibliovault`
    # mapped to environment variable names.
    #
    # @type [Hash{Symbol=>String}]
    #
    BV_KEY_ENV = AWS_KEYS.transform_values { _1.sub(/^AWS_/, 'BV_') }.freeze

    # Mappings for groups of values from `Rails.application.credentials`.
    #
    # @type [Hash{Symbol=>Hash{Symbol=>String}}]
    #
    CREDENTIAL_GROUPS = {
      s3:           S3_KEY_ENV,
      bibliovault:  BV_KEY_ENV,
    }.freeze

    # Get `Rails.application.credentials` entries.
    #
    # Most entries are an environment variable name and value, except for
    # hierarchical groupings of AWS credentials.  (Any other hierarchical
    # groupings are ignored if found.)
    #
    # @param [Boolean] output         If *false*, do not log ignored groups.
    # @param [Boolean] fatal          If *true*, fail on ignored groups.
    #
    # @return [Hash{String=>any}]
    #
    def get_credentials(output: true, fatal: false)
      Rails.application.credentials.to_hash.tap { |items|
        CREDENTIAL_GROUPS.each_pair do |group, mapping|
          if (hash = items.delete(group)).is_a?(Hash)
            mapping.each_pair do |key, var|
              items[var] = hash[key] if hash[key]
            end
          end
        end
        if (remaining_groups = items.select { |_, v| v.is_a?(Hash) }).present?
          issue = "#{__method__}: ignored groups: #{remaining_groups.inspect}"
          Log.info(issue) if output
          raise issue     if fatal
          items.except!(*remaining_groups.keys)
        end
      }.transform_keys { _1.to_s.upcase }.sort_by { _1 }.to_h
    end

    # Get "en.emma.env_var" configuration entries.
    #
    # @return [Hash{String=>any}]
    #
    def get_yaml
      items = config_all.dig(:env_var, application_deployment)
      items.transform_keys { _1.to_s.upcase }.sort_by { _1 }.to_h
    end

    # Get `ENV` entries.
    #
    # @return [Hash{String=>String}]
    #
    def get_env
      ENV.to_hash.sort_by { _1 }.to_h
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Form an I18n path.
  #
  # @param [Array<String,Symbol,nil>] path
  #
  # @return [Symbol]
  #
  def config_key(*path)
    key = path.compact.map!(&:to_s)
    key.map! { _1.split('.') }.flatten! if key.join.include?('.')
    key.map! { config_key_fix(_1) }
    key.join('.').to_sym
  end

  # Generate I18n paths.
  #
  # The first returned element should be used as the key for I18n#translate and
  # the remaining elements should be used passed as the :default option.
  #
  # @param [Array<String,Symbol,nil>, String, Symbol, nil] base
  # @param [Array<String,Symbol,nil>]                      path
  #
  # @return [Array<Symbol>]
  #
  def config_keys(base, *path)
    Array.wrap(base).map do |key|
      config_key(*key, *path)
    end
  end

  # Configuration sections under "en.emma.page" that may hold values for
  # *item*.
  #
  # The first returned element should be used as the key for I18n#translate and
  # the remaining elements should be used passed as the :default option.
  #
  # @param [Array<Symbol,String>] base
  # @param [Symbol, String, nil]  item
  # @param [Symbol, String]       root
  #
  # @return [Array<Symbol>]
  #
  def config_page_keys(*base, item, root: CONFIG_ROOT)
    base.flatten!
    base.compact!
    return []            if base.blank? && item.blank?
    return [item.to_sym] if base.blank? && item.start_with?(root)
    keys = []
    while base.present?
      type, subtype = base[0], base[1..-1]
      if subtype.blank?
        keys << [root, :page, type, :action]
        keys << [root, :page, type]
        keys << [root, :page, :_generic, type, :action]
        keys << [root, :page, :_generic, type]
      elsif subtype.first.to_sym == :action
        keys << [root, :page, type, *subtype]
        keys << [root, :page, :_generic, type, *subtype]
      else
        keys << [root, :page, type, :action, *subtype]
        keys << [root, :page, type, *subtype]
        keys << [root, :page, *subtype]
        keys << [root, :page, :_generic, type, :action, *subtype]
        keys << [root, :page, :_generic, type, *subtype]
        keys << [root, :page, :_generic, *subtype]
      end
      base.pop
    end
    if item.present?
      keys << [root, :page, :_generic]
      keys << [root, :page]
    end
    config_keys(keys, *item)
  end

  # Configuration sections that may hold message values for *item*.
  #
  # The first returned element should be used as the key for I18n#translate and
  # the remaining elements should be used passed as the :default option.
  #
  # @param [Array<Symbol,String>] base
  # @param [Symbol, String, nil]  item
  # @param [Symbol, String]       root
  #
  # @return [Array<Symbol>]
  #
  def config_term_keys(*base, item, root: CONFIG_ROOT)
    base.flatten!
    base.compact!
    return []            if base.blank? && item.blank?
    return [item.to_sym] if base.blank? && item.start_with?(root)
    term = []
    page = []
    while base.present?
      type, subtype = base[0], base[1..-1]
      if subtype.present?
        term << [root, :term, type, :action, *subtype]
        page << [root, :page, type, :action, *subtype]
        term << [root, :term, type, *subtype]
        page << [root, :page, type, *subtype]
        term << [root, :term, :_generic, :action, type, *subtype]
        term << [root, :term, :_generic, :action, *subtype]
        term << [root, :term, :_generic, type, *subtype]
        term << [root, :term, :_generic, *subtype]
      else
        term << [root, :term, :_generic, :action, type]
        term << [root, :term, :_generic, type]
        term << [root, :term, type]
        page << [root, :page, type]
      end
      base.pop
    end
    if item.present?
      term << [root, :term, :_vocabulary]
      term << [root, :term, :_common]
    end
    keys = [*term, *page]
    config_keys(keys, *item)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  CONFIG_ITEM_OPT = %i[fallback default cfg_warn cfg_fatal root].freeze

  # @private
  I18N_OPT = %i[throw raise locale].freeze

  # The configuration entry specified by *key* or alternate *default*
  # locations.
  #
  # If *key* is an array, the first element is used as the I18n#translate key
  # and the remaining elements are passed as the :default option.
  #
  # @param [any]      key             I18n path(s) (Symbol, String, Array)
  # @param [any, nil] fallback        Returned if the item is not found.
  # @param [any, nil] default         Passed to I18n#translate.
  # @param [Hash]     opt             Passed to I18n#translate except:
  #
  # @option opt [Boolean] :cfg_fatal  Raise if the item is not found.
  # @option opt [Boolean] :cfg_warn   Log a warning if the item is not found.
  #
  # @return [any, nil]                Or the type of *fallback*.
  #
  def config_entry(key, fallback: nil, default: nil, **opt)
    c_opt = opt.extract!(*CONFIG_ITEM_OPT)
    i_opt = opt.extract!(*I18N_OPT)
    if key.is_a?(Array)
      key = key.map { config_path_fix(_1.to_sym, **c_opt) }
      key, default = key.first, [*key[1..-1], *default].compact.presence
    else
      key = config_path_fix(key, **c_opt)
      default &&= Array.wrap(default).compact.presence
    end
    if c_opt[:cfg_fatal] || c_opt[:cfg_warn] || i_opt[:raise]
      c_opt[:cfg_fatal] = false if c_opt[:cfg_warn]
      item = config_entry_fetch(key, default, **c_opt, **i_opt, **opt)
    else
      default << nil if default
      item = config_entry_get(key, default: default, **i_opt, **opt)
    end
    opt.presence && config_deep_interpolate(item, **opt) || item || fallback
  end

  # The configuration item path specified by *path*.
  #
  # @param [Array<String,Symbol,nil>] path
  # @param [Hash]                     opt   To #config_entry.
  #
  # @return [any, nil]
  #
  def config_item(*path, **opt)
    key = config_key(*path)
    config_entry(key, **opt)
  end

  # The configuration section path specified by *path*.
  #
  # @param [Array<String,Symbol,nil>] path
  # @param [Hash]                     opt   To #config_entry.
  #
  # @return [Hash]
  #
  def config_section(*path, **opt)
    key = config_key(*path)
    config_entry(key, **opt) || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # YAML 1.1 boolean values (which cannot be used as keys).
  #
  # @type [Array<String>]
  #
  YAML_BOOLEAN = %w(true false on off y n yes no).freeze

  # @private
  YAML_KEY_FIX = /\.(#{YAML_BOOLEAN.join('|')})$/i.freeze

  # Adjust key values to match the actual keys in the configuration file.
  #
  # @param [Symbol, String] key
  #
  # @return [String]
  #
  def config_key_fix(key)
    k = key.to_s
    k.include?('/') ? k.underscore.tr('/', '_') : k.sub(YAML_KEY_FIX, '_\1')
  end

  # Ensure an absolute path through the configuration hierarchy.
  #
  # @param [Symbol, String] path
  # @param [Symbol, String] root
  #
  # @return [Symbol]
  #
  def config_path_fix(path, root: CONFIG_ROOT, **)
    path = "#{root}.#{path}" unless path.start_with?("#{root}.")
    path.to_sym
  end

  # Get an item from configuration.
  #
  # @param [String, Symbol] key       I18n path.
  # @param [Symbol, String] root
  # @param [Hash]           opt       Passed to I18n#translate.
  #
  # @option opt [Boolean] :raise      Raise exception if item not found.
  #
  # @return [any, nil]
  #
  def config_entry_get(key, root: CONFIG_ROOT, **opt)
    unless key.is_a?(String) || key.is_a?(Symbol)
      raise ArgumentError, "#{__method__}: disallowed key #{key.inspect}"
    end
    root  = root.end_with?('.') ? root.to_s : "#{root}."
    c_opt = opt.extract!(*CONFIG_ITEM_OPT)
    keys, literals = [], []
    Array.wrap(c_opt[:default]).each do |v|
      break literals << v unless v.is_a?(Symbol) # A literal (non-key) value.
      keys << v # Only include the keys before the first literal value.
    end
    if key.start_with?(root)
      result = found = missing = nil
      [key, *keys].find do |k|
        if k.start_with?(root)
          path = k.to_s.delete_prefix(root).split('.').map!(&:to_sym)
          k = path.pop
          v = config_all
          v = v.dig(*path) if path.present?
          v = v[k] if (found = v.is_a?(Hash) && v.key?(k))
        else
          missing ||= "missing_key_#{rand}"
          v = I18n.t(k, default: missing)
          found = (v != missing)
        end
        break (result = v) if found
      end
      raise MissingTranslation.new(key, *keys) unless found || !opt[:raise]
    else
      keys << nil unless opt[:raise]
      result = I18n.t(key, default: keys, **opt)
    end
    result || c_opt[:fallback] || literals.first
  end

  # Fetch a configuration item and raise an exception if not found.
  #
  # @param [Symbol, String]  key      I18n path.
  # @param [Array, any, nil] other    Alternate location(s)
  # @param [Hash]            opt      Passed to I18n#translate except:
  #
  # @option opt [Boolean] :cfg_fatal  If *false*, no raise if item not found.
  # @option opt [Boolean] :cfg_warn   If *false*, do not log a warning.
  #
  # @return [any, nil]
  #
  def config_entry_fetch(key, other = nil, **opt)
    default = ([*other, *opt[:default]].compact if other || opt[:default])
    c_opt   = opt.extract!(*CONFIG_ITEM_OPT)
    Log.warn { "#{__method__}: fallback not allowed" } if c_opt.key?(:fallback)
    opt[:default] = default if default.present?
    config_entry_get(key, raise: true, **opt)
  rescue I18n::MissingTranslation, I18n::MissingTranslationData => error
    error = MissingTranslationBase.wrap(error)
    raise error unless false?(c_opt[:cfg_fatal])
    Log.warn("#{__method__}: #{error.message}") unless false?(c_opt[:cfg_warn])
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Text value from the most specific match found for *item* within the
  # configuration location(s) specified by *base* under #config_term_keys.
  #
  # @param [Array<Symbol,String>] base
  # @param [Symbol, String]       item
  # @param [Hash]                 opt   To #config_entry.
  #
  # @return [String]
  #
  def config_term(*base, item, **opt)
    keys = config_term_keys(*base, item)
    config_entry(keys, **opt) || [*base, item].flatten.compact.join(' ')
  end

  # Configuration text section built up from all of the matches found within
  # the configuration locations under #config_term_keys.
  #
  # If *opt* interpolation values are given they will be attempted on all
  # strings copied from the section.
  #
  # @param [Array<Symbol,String>] base
  # @param [Symbol, String]       item
  # @param [Hash]                 opt   To #config_section
  #
  # @return [Hash]
  #
  def config_term_section(*base, item, **opt)
    base, item = [[item], nil] if base.empty?
    keys = config_term_keys(*base, item)
    vals = keys.reverse.map! { config_section(_1, **opt) }.compact_blank
    vals.select { _1.is_a?(Hash) }.prepend({}).reduce(&:rmerge!)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Value from the most specific match found for *item* within the
  # configuration location(s) specified by *base* under #config_page_keys.
  #
  # @param [Array<Symbol,String>] base
  # @param [Symbol, String]       item
  # @param [Hash]                 opt   To #config_entry.
  #
  # @return [any, nil]
  #
  def config_page(*base, item, **opt)
    keys = config_page_keys(*base, item)
    config_entry(keys, **opt)
  end

  # Configuration text section built up from all of the matches found within
  # the configuration locations under #config_page_keys.
  #
  # If *opt* interpolation values are given they will be attempted on all
  # strings copied from the section.
  #
  # @param [Array<Symbol,String>] base
  # @param [Symbol, String]       item
  # @param [Hash]                 opt   To #config_section
  #
  # @return [Hash]
  #
  def config_page_section(*base, item, **opt)
    keys = config_page_keys(*base, item)
    vals = keys.reverse.map! { config_section(_1, **opt) }.compact_blank
    vals.select { _1.is_a?(Hash) }.prepend({}).reduce(&:rmerge!)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Attempt to apply interpolations to all strings in *item*.
  #
  # @param [any, nil] item           Hash, Array, String
  # @param [Hash]     opt
  #
  # @return [any, nil]
  #
  def config_deep_interpolate(item, **opt)
    return item unless opt.present?
    opt[:id] = Emma::Common::FormatMethods.quote(opt[:id]) if opt.key?(:id)
    Emma::Common::FormatMethods.deep_interpolate(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return a description of differences between two values.
  #
  # @param [any, nil]       v1
  # @param [any, nil]       v2
  # @param [String, Symbol] n1
  # @param [String, Symbol] n2
  # @param [Boolean]        exact
  # @param [Boolean]        verbose
  #
  # @return [String, nil]
  #
  def cfg_diff(v1, v2, n1: nil, n2: nil, exact: false, verbose: true, **)
    o1, o2 = v1, v2
    n1, n2 = (n1 || 'value1'), (n2 || 'value2')
    added  = missing = nil
    opt    = { exact: exact }

    diff =
      if v1 == v2
        nil # No difference.

      elsif (t1, t2 = v1.class, v2.class) && !(t1 <= t2) && !(t2 <= t1)
        ["#{n1} is_a #{t1}   ....but....   #{n2} is_a #{t2}"]

      elsif v1.is_a?(String) && !exact && (v1.squish == v2.squish)
        nil # Only differ by white space.

      elsif !v1.respond_to?(:each)
        v1, v2 = [v1, v2].map { cfg_inspect(_1) }
        ["#{n1} == #{v1}   ....but....   #{n2} == #{v2}"]

      elsif (s1, s2 = v1.size, v2.size) && s1.zero? && s2.zero?
        nil # Both items are empty.

      elsif s1.zero? || s2.zero?
        ["#{n1} size #{s1}   ....but....   #{n2} size #{s2}"]

      elsif v1.is_a?(Array)
        missing = v1 - v2
        added   = v2 - v1
        v1, v2  = v1.excluding(*missing), v2.excluding(*added)
        v1, v2  = v1.sort_by(&:to_s), v2.sort_by(&:to_s) unless exact
        [v1.size, v2.size].min.times.map { |i|
          cfg_diff(v1[i], v2[i], n1: "#{n1}[#{i}]", n2: "#{n2}[#{i}]", **opt)
        }.compact

      else # if v1.is_a?(Hash)
        k1, k2  = v1.keys, v2.keys
        missing = v1.slice(*(k1 - k2))
        added   = v2.slice(*(k2 - k1))
        k1.excluding(*missing.keys).map { |k|
          cfg_diff(v1[k], v2[k], n1: "#{n1}[:#{k}]", n2: "#{n2}[:#{k}]", **opt)
        }.compact
      end

    if (values = missing).present?
      vals = cfg_inspect(values)
      vals.prepend("keys #{values.keys.inspect} ->\n\t") if values.is_a?(Hash)
      diff.unshift("#{n2}   --missing--   #{vals}")
    end
    if (values = added).present?
      vals = cfg_inspect(values)
      vals.prepend("keys #{values.keys.inspect} ->\n\t") if values.is_a?(Hash)
      diff.unshift("#{n2}   +++added+++   #{vals}")
    end
    if diff.present?
      diff.unshift("#{n2} = #{o2.inspect}") if verbose
      diff.unshift("#{n1} = #{o1.inspect}") if verbose
      diff.join("\n")
    end
  end

  # Render a value description for #cfg_diff.
  #
  # @param [any, nil] value
  # @param [Integer]  limit
  #
  # @return [String]
  #
  def cfg_inspect(value, limit: 64_000) # TODO: was 64
    case value
      when Hash
        value = value.map { "#{_1}: #{cfg_inspect(_2, limit: limit)}" }
        '{ %s }' % value.join(', ').truncate(limit * 2)
      when Array
        value = value.map { cfg_inspect(_1, limit: limit) }
        '[%s]' % value.join(', ').truncate(limit * 2)
      when String
        value = value.inspect
        value = value.truncate(limit) << '"' if value.size > limit
        value.to_s
      else
        value.inspect.truncate(limit)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Included in custom exception variants.
  #
  module MissingTranslationBase

    include I18n::MissingTranslation::Base

    # =========================================================================
    # :section: I18n::MissingTranslation::Base overrides
    # =========================================================================

    public

    def initialize(key, *other, **opt)
      if (src = key).is_a?(I18n::MissingTranslation::Base)
        super(src.locale, src.key, src.options)
      else
        locale = opt.delete(:locale) || I18n.config.locale
        if other.present?
          opt[:default] = [*other, *opt[:default]]
        elsif opt[:default]
          opt[:default] = Array.wrap(opt[:default]).compact.presence
        end
        super(locale, key, opt)
      end
    end

    def message
      other = options[:default]
      keys  = [key, *other].map! { normalized_option(_1).to_sym.inspect }
      msg   = 'missing key'.pluralize(keys.size)
      keys  = keys.many? ? ('[%s]' % keys.join(', ')) : keys.first
      "Translation missing: #{msg} #{keys}"
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def self.wrap(src)
      case src.class
        when I18n::MissingTranslationData then MissingTranslationData.new(src)
        when I18n::MissingTranslation     then MissingTranslation.new(src)
        else                                   src
      end
    end

  end

  # Custom variant which redefines the exception message.
  #
  class MissingTranslation < I18n::MissingTranslation
    include MissingTranslationBase
  end

  # Custom variant which redefines the exception message.
  #
  class MissingTranslationData < I18n::MissingTranslationData
    include MissingTranslationBase
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

class Object

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Configuration
    extend  Configuration
  end
  # :nocov:

  Configuration.include_and_extend(self)

end

# This holds appropriately-typed configuration values taken from `ENV`,
# `Rails.application.credentials`, or "en.emma.env_var" YAML configuration.
#
# @type [Configuration::EnvVar]
#
ENV_VAR = Configuration::EnvVar.instance

__loading_end(__FILE__)

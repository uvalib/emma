# lib/emma/config.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# General access into "config/locales/**.yml" configuration information.
#
module Emma::Config

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

  # All "en.emma.*" configuration values.
  class Data

    include Singleton

    # All "en.emma.*" configuration values.
    def self.all = instance.all

    # All "en.emma.*" configuration values.
    def all = @all ||= fetch_all || fetch_all(initialize: true)

    protected

    def fetch_all(initialize: false)
      if initialize
        require 'active_support/i18n'
        require 'active_support/i18n_railtie'
        I18n.load_path +=
          Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
        I18n.load_path.uniq!
        I18n::Railtie.initialize_i18n(Rails.application)
      end
      I18n.t(CONFIG_ROOT, default: nil)
    end

  end

  # All "en.emma.*" configuration values.
  #
  # @return [Hash]
  #
  def config_all
    Emma::Config::Data.all
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # YAML 1.1 boolean values (which cannot be used as keys).
  #
  # @type [Array<String>]
  #
  YAML_BOOLEAN = %w(true false on off y n yes no).freeze

  # @private
  YAML_KEY_FIX = /\.(#{YAML_BOOLEAN.join('|')})$/i.freeze

  # Generate I18n paths.
  #
  # The first returned element should be used as the key for I18n#translate and
  # the remaining elements should be used passed as the :default option.
  #
  # @param [any, nil] base
  # @param [Array]    path
  #
  # @return [Array<Symbol>]
  #
  def config_keys(base, *path)
    keys = base.is_a?(Array) ? base.flatten : [base]
    keys.map! do |key|
      key = [key, *path].compact.map!(&:to_s)
      key.map! { |k| k.split('.') }.flatten! if key.join.include?('.')
      key.map! { |k| k.sub(YAML_KEY_FIX, '_\1') }
      key.join('.').to_sym
    end
  end

  # Configuration sections that may hold message values for *item*.
  #
  # The first returned element should be used as the key for I18n#translate and
  # the remaining elements should be used passed as the :default option.
  #
  # @param [Array<Symbol>]  base
  # @param [Symbol, nil]    item
  # @param [Symbol, String] root
  #
  # @return [Array<Symbol>]
  #
  def config_text_keys(*base, item, root: CONFIG_ROOT)
    keys = []
    base.flatten!
    while base.present?
      if base.many?
        type, subtype = base[0], base[1..-1]
        keys << [root, *type, *subtype, 'messages']
        keys << [root, *type, 'messages', *subtype]
        keys << [root, 'messages', *type, *subtype]
        keys << [root, 'messages', *subtype]
      else
        keys << [root, *base, 'messages']
        keys << [root, 'messages', *base]
      end
      base.pop
    end
    keys.map! { |key| Array.wrap(key).join('.').to_sym }
    keys << :"#{root}.messages" if item.present?
    config_keys(keys, *item)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  CONFIG_ITEM_OPT = %i[fallback default cfg_warn cfg_fatal].freeze

  # @private
  I18N_OPT = %i[throw raise locale].freeze

  # The configuration item specified by *key* or alternate *default* locations.
  #
  # If *path* is an array, the first element is used as the I18n#translate key
  # and the remaining elements are passed as the :default option.
  #
  # @param [any]           key        I18n path(s) (Symbol, String, Array)
  # @param [any, nil]      fallback   Returned if the item is not found.
  # @param [any, nil]      default    Passed to I18n#translate.
  # @param [Symbol,String] root
  # @param [Hash]          opt        Passed to I18n#translate except:
  #
  # @option opt [Boolean] :cfg_fatal  Raise if the item is not found.
  # @option opt [Boolean] :cfg_warn   Log a warning if the item is not found.
  #
  # @return [any, nil]                Or the type of *fallback*.
  #
  def config_item(key, fallback: nil, default: nil, root: CONFIG_ROOT, **opt)
    key, default = key.first, [*key[1..-1], *default] if key.is_a?(Array)
    other = default && Array.wrap(default).compact.presence
    key   = key.to_s
    key   = "#{root}.#{key}" unless key.split('.').first == root
    c_opt = opt.extract!(*CONFIG_ITEM_OPT)
    i_opt = opt.extract!(*I18N_OPT)
    if c_opt[:cfg_fatal] || c_opt[:cfg_warn] || i_opt[:raise]
      c_opt[:cfg_fatal] = false if c_opt[:cfg_warn]
      item = config_item_fetch(key, other, **c_opt, **i_opt, **opt)
    else
      other << nil if other.is_a?(Array)
      item = config_item_get(key, default: other, **i_opt, **opt)
    end
    opt.presence && config_interpolate(item, **opt) || item || fallback
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
  def config_item_get(key, root: CONFIG_ROOT, **opt)
    unless key.is_a?(String) || key.is_a?(Symbol)
      raise ArgumentError, "#{__method__}: disallowed key #{key.inspect}"
    end
    fatal = opt[:raise]
    c_opt = opt.extract!(*CONFIG_ITEM_OPT)
    keys, vals = [], []
    Array.wrap(c_opt[:default]).each do |v|
      break vals << v unless v.is_a?(Symbol) # A literal (non-key) value.
      keys << v # Only include the keys before the first literal value.
    end
    fallback = c_opt[:fallback] || vals.first
    missing  = nil
    prefix   = "#{root}."
    if key.start_with?(prefix)
      result = found = nil
      [key, *keys].find do |k|
        if k.start_with?(prefix)
          path = k.to_s.delete_prefix(prefix).split('.').map!(&:to_sym)
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
      raise MissingTranslation.new(key, *keys) if fatal && !found
      result || fallback
    else
      keys << nil unless fatal
      I18n.t(key, default: keys, **opt) || fallback
    end
  end

  # Fetch a configuration item and raise an exception if not found.
  #
  # @param [Symbol, String]  key      I18n path.
  # @param [Array, any, nil] other    Alternate location(s)
  # @param [Hash]            opt      Passed to I18n#translate except:
  #
  # @option opt [Boolean] :cfg_fatal  If *false* do not raise if item not found
  # @option opt [Boolean] :cfg_warn   If *false* do not log a warning.
  #
  # @return [any, nil]
  #
  def config_item_fetch(key, other = nil, **opt)
    default = ([*other, *opt[:default]].compact if other || opt[:default])
    c_opt   = opt.extract!(*CONFIG_ITEM_OPT)
    Log.warn { "#{__method__}: fallback not allowed" } if c_opt.key?(:fallback)
    opt[:default] = default if default.present?
    config_item_get(key, raise: true, **opt)
  rescue I18n::MissingTranslation, I18n::MissingTranslationData => error
    error = MissingTranslationBase.wrap(error)
    raise error unless false?(c_opt[:cfg_fatal])
    Log.warn("#{__method__}: #{error.message}") unless false?(c_opt[:cfg_warn])
  end

  # The configuration section specified by *key* or *default* locations.
  #
  # @param [any]  key                 I18n path(s) (Symbol, String, Array)
  # @param [Hash] opt                 To #config_deep_interpolate except for
  #                                     #CONFIG_ITEM_OPT to #config_item.
  #
  # @return [Hash]                    Or the type of *fallback*.
  #
  def config_section(key, **opt)
    c_opt = opt.extract!(*CONFIG_ITEM_OPT, *I18N_OPT)
    item  = config_item(key, **c_opt)
    opt.presence && config_deep_interpolate(item, **opt) || item || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Text value from the most specific match found for *item* within the
  # configuration location(s) specified by *base* under #config_text_keys.
  #
  # @param [Array<Symbol>] base
  # @param [Symbol]        item
  # @param [Hash]          opt        To #config_item.
  #
  # @return [String]
  #
  def config_text(*base, item, **opt)
    keys = config_text_keys(*base, item)
    config_item(keys, **opt) || [*base, item].flatten.compact.join(' ')
  end

  # Configuration text section built up from all of the matches found within
  # the configuration locations under #config_text_keys.
  #
  # If *opt* interpolation values are given they will be attempted on all
  # strings copied from the section.
  #
  # @param [Array<Symbol>] base
  # @param [Symbol]        item
  # @param [Hash]          opt        Optional interpolation values except
  #                                     #CONFIG_ITEM_OPT to #config_section
  #
  # @return [Hash]
  #
  def config_text_section(*base, item, **opt)
    base, item = [[item], nil] if base.empty?
    c_opt = opt.extract!(*CONFIG_ITEM_OPT, *I18N_OPT)
    keys  = config_text_keys(*base, item)
    vals  = keys.reverse.map { |k| config_section(k, **c_opt) }.compact_blank!
    hash  = vals.select { |v| v.is_a?(Hash) }.prepend({}).reduce(&:rmerge!)
    opt.presence && config_deep_interpolate(hash, **opt) || hash
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Attempt to apply interpolations to *item*.
  #
  # @param [any, nil] item            String
  # @param [Hash]     opt             Passed to #interpolate
  #
  # @return [String, any, nil]
  #
  def config_interpolate(item, **opt)
    return item unless item.is_a?(String) && opt.present?
    opt[:id] = Emma::Common::FormatMethods.quote(opt[:id]) if opt.key?(:id)
    Emma::Common::FormatMethods.interpolate(item, **opt)
  end

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
      keys  = [key, *other].map! { |k| normalized_option(k).to_sym.inspect }
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
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Emma::Config
    extend  Emma::Config
    # :nocov:
  end

  Emma::Config.include_and_extend(self)

end

__loading_end(__FILE__)

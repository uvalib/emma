// app/assets/javascripts/shared/lookup-request.js


import { BaseClass }                        from '../shared/base-class'
import { isDefined, isPresent, notDefined } from '../shared/definitions'
import { arrayWrap, deepFreeze }            from '../shared/objects'


// ============================================================================
// Class LookupRequest
// ============================================================================

// noinspection JSUnusedGlobalSymbols
/**
 * A lookup request message formed by parsing one or more term strings.
 */
export class LookupRequest extends BaseClass {

    static CLASS_NAME = 'LookupRequest';

    /**
     * The set of valid identifier prefixes.
     *
     * @readonly
     * @enum {string}
     */
    static ID_TYPES = deepFreeze([
        'isbn',
        'issn',
        'doi',
        'oclc',
        'lccn',
    ]);

    /**
     * The set of valid query term prefixes.
     *
     * @readonly
     * @enum {string}
     */
    static QUERY_TYPES = deepFreeze([
        'author',
        'title',
        'keyword',
    ]);

    /**
     * The set of valid limiter prefixes.
     *
     * @readonly
     * @enum {string}
     */
    static LIMIT_TYPES = deepFreeze([
        // TODO: none yet
    ]);

    /**
     * LookupRequestObject
     *
     * @typedef {{
     *     ids?:   string[],
     *     query?: string[],
     *     limit?: string[],
     * }} LookupRequestObject
     */

    /**
     * Each request type and the valid search term prefixes associated with it.
     *
     * @readonly
     * @type {LookupRequestObject}
     */
    static REQUEST_TYPE = deepFreeze({
        ids:    this.ID_TYPES,
        query:  this.QUERY_TYPES,
        limit:  this.LIMIT_TYPES,
    });

    static DEF_ID_TYPE      = 'isbn';
    static DEF_QUERY_TYPE   = 'keyword';
    static DEF_REQUEST_TYPE = 'query';

    // noinspection JSValidateTypes
    /**
     * A blank object containing an array value for every key defined by
     * {@link REQUEST_TYPE}.
     *
     * @readonly
     * @type {LookupRequestObject}
     */
    static TEMPLATE = deepFreeze(
        Object.fromEntries(Object.keys(this.REQUEST_TYPE).map(k => [k, []]))
    );

    /**
     * Selective URL encoding.
     *
     * @readonly
     * @type {{[char: string]: string}}
     */
    static CHARACTER_MAPPING = deepFreeze({
        '"': '%22',
        "'": '%27',
        ':': '%3A'
    });

    /**
     * Default set of characters interpreted as separating terms.
     *
     * @readonly
     * @type {string}
     */
    static DEF_SEPARATORS = '|';

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {string|string[]|LookupRequest|LookupRequestObject} [terms]
     * @param {string|string[]} [chars]     Separator character(s).
     */
    constructor(terms, chars) {
        super();
        this.separators   = Array.isArray(chars) ? chars.join('') : chars;
        this.separators ||= this.constructor.DEF_SEPARATORS;
        this.parts = this._blankParts();
        this.add(terms);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get ids()    { return this.parts.ids   || [] }
    get query()  { return this.parts.query || [] }
    get limit()  { return this.parts.limit || [] }

    /**
     * A request object with only the terms that would actually be used for a
     * request.
     *
     * @returns {LookupRequestObject}
     */
    get requestParts() {
        let result = this._blankParts();
        let source = isPresent(this.ids) ? { ids: this.ids } : this.parts;
        $.extend(true, result, source);
        return result;
    }

    /**
     * The individual "prefix:value" terms that would actually be used for a
     * request.
     *
     * @returns {string[]}
     */
    get terms() {
        return isPresent(this.ids) ? this.ids : this.allTerms;
    }

    /**
     * All individual "prefix:value" terms.
     *
     * @returns {string[]}
     */
    get allTerms() {
        return Object.values(this.parts).flat();
    }

    /**
     * The total number of individual "prefix:value" terms.
     *
     * @returns {number}
     */
    get length() {
        return this.allTerms.length;
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Clear all terms.
     */
    clear() {
        this.parts = this._blankParts();
    }

    /**
     * Add one or more terms.
     *
     * @param {string|string[]|LookupRequest|LookupRequestObject} [term]
     * @param {string}                                            [prefix]
     */
    add(term, prefix) {
        let req;
        if (Array.isArray(term) || (typeof term === 'string')) {
            req = this.parse(term, prefix);
        } else {
            req = term;
            if (prefix) {
                this._warn(
                    `prefix "${prefix}" ignored for ${typeof(term)} term`
                );
            }
        }
        if (isPresent(req)) {
            let req_parts = req.parts || req;
            this._appendParts(this.parts, req_parts);
        } else if (isDefined(req)) {
            this._warn('nothing to add');
        }
    }

    /**
     * Create a lookup request object from the provided terms.
     *
     * @param {string|string[]} term_values
     * @param {string}          [term_prefix]
     *
     * @returns {LookupRequestObject}
     */
    parse(term_values, term_prefix) {
        let parts = this._blankParts();
        let terms = arrayWrap(term_values);

        // Apply the provided prefix to each of the term value strings.
        // (These still go through extractParts in order to clean the values.)
        if (term_prefix) {
            const prefix = term_prefix.toLowerCase();
            if (!this._validPrefix(prefix)) {
                this._warn(`prefix "${term_prefix}" is invalid`);
                return parts;
            }
            terms = terms.map(term => `${prefix}:${term}`);
        }

        // Put each search term into the appropriate slot in the returned
        // request object.
        const REQUEST_TYPE     = this.constructor.REQUEST_TYPE;
        const DEF_REQUEST_TYPE = this.constructor.DEF_REQUEST_TYPE;
        let pairs = terms.map(term => this.extractParts(term)).flat(1);
        pairs.forEach(function(pair) {
            let [prefix, value] = pair;
            let term = `${prefix}:${value}`;
            let type;
            $.each(REQUEST_TYPE, function(req_type, prefixes) {
                if (prefixes.includes(prefix)) {
                    type = req_type;
                }
                return !type; // break loop if type found
            });
            type ||= DEF_REQUEST_TYPE;
            parts[type].push(term);
        });
        return parts;
    }

    /**
     * Split the terms string into an array of prefix/value pairs.
     *
     * * prefix:value
     * * prefix:'value'     If the value string was single-quoted.
     * * prefix:"value"     If the value string was double-quoted.
     *
     * Terms can be separated by one or more space, tab, '|' characters.
     * Values which contain any of those characters must be quoted, however the
     * quotes are removed from the returned elements.
     *
     * @param {string} terms
     *
     * @returns {[string,string][]}
     */
    extractParts(terms) {
        const ID_TYPE    = this.constructor.DEF_ID_TYPE;
        const QUERY_TYPE = this.constructor.DEF_QUERY_TYPE;
        const encode     = this._encodeValue.bind(this);
        const parts      = terms.matchAll(this._termMatcher);
        return [...parts].map(function(part) {
            let prefix = part[2]?.toLowerCase();
            let value  =
                part[4] || // value inside double quotes
                part[5] || // value inside single quotes
                part[6];   // value if unquoted
            if (!(value = value?.trim())) {
                return [];
            } else if (value.match(/^\d+$/)) {
                return [(prefix || ID_TYPE), value];
            } else {
                return [(prefix || QUERY_TYPE), encode(value)];
            }
        });
    }

    // ========================================================================
    // Protected properties
    // ========================================================================

    get _prefixMatch() { return `[^${this.separators}"']+`; }
    get _valueMatch()  { return `[^${this.separators}]+`; }
    get _termMatcher() { return this.term_regex ||= this._makeTermMatcher() }

    // ========================================================================
    // Protected methods
    // ========================================================================

    /**
     * Indicate whether the supplied item is a valid prefix.
     *
     * @param {string} prefix
     *
     * @returns {boolean}
     */
    _validPrefix(prefix) {
        return this.constructor.validPrefix(prefix);
    }

    /**
     * Generate a new empty request object.
     *
     * @returns {LookupRequestObject}
     * @private
     */
    _blankParts() {
        return this.constructor.blankParts();
    }

    /**
     * Append the elements from *src* to *dst*.
     *
     * @param {object} dst
     * @param {object} src
     *
     * @returns {object}
     * @private
     */
    _appendParts(dst, src) {
        let src_val;
        $.each(dst, function(key, val) {
            if (isPresent(src_val = src[key])) {
                dst[key] = Array.from(new Set([...val, ...src_val]));
            }
        });
        return dst;
    }

    /**
     * Selectively URL-encode certain value characters.
     *
     * @param {string} value
     *
     * @returns {string}
     */
    _encodeValue(value) {
        const CHAR_MAP = this.constructor.CHARACTER_MAPPING;
        return Object.keys(CHAR_MAP).reduce(
            (result, char) => result.replaceAll(char, CHAR_MAP[char]),
            value
        );
    }

    /**
     * Generate the matcher for {@link extractParts}.
     * 
     * @returns {RegExp}
     */
    _makeTermMatcher() {
        const PRE_ = this._prefixMatch;
        const VAL_ = this._valueMatch;
        // part        ____2____             ___4___   ___5___  ____6____
        const TERM = `((${PRE_})\\s*:\\s*)?("([^"]*)"|'([^']*)'|(${VAL_}))`;
        return new RegExp(TERM, 'g');
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get idPrefixes()    { return this.ID_TYPES }
    static get queryPrefixes() { return this.QUERY_TYPES }
    static get limitPrefixes() { return this.LIMIT_TYPES }
    static get allPrefixes()   { return this.prefixes ||= this._prefixList(); }

    // ========================================================================
    // Class protected methods
    // ========================================================================

    /**
     * All valid search type prefixes.
     *
     * @returns {string[]}
     */
    static _prefixList() {
        return Object.values(this.REQUEST_TYPE).flat();
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Indicate whether the supplied item is a valid prefix.
     *
     * @param {string} prefix
     *
     * @returns {boolean}
     */
    static validPrefix(prefix) {
        return this.allPrefixes.includes(prefix);
    }

    /**
     * Generate a new empty request object.
     *
     * @returns {LookupRequestObject}
     */
    static blankParts() {
        return $.extend(true, {}, this.TEMPLATE);
    }

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {string|string[]|LookupRequest|LookupRequestObject} item
     * @param {string|string[]} [chars] Passed to constructor (if required).
     *
     * @returns {LookupRequest}
     */
    static wrap(item, chars) {
        if (item instanceof this) {
            if (notDefined(chars) || (chars === item.separators)) {
                return item;
            }
        }
        return new this(item, chars);
    }
}

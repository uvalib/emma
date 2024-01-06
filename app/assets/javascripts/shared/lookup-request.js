// app/assets/javascripts/shared/lookup-request.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }                         from '../application/debug';
import { arrayWrap }                        from './arrays';
import { ChannelRequest }                   from './channel-request';
import { isMissing, isPresent, notDefined } from './definitions';
import { deepFreeze, toObject }             from './objects';


const MODULE = 'LookupRequest';
const DEBUG  = true;

AppDebug.file('shared/lookup-request', MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {ChannelRequestPayload} LookupRequestPayload
 *
 * @property {string[]} [ids]         One or more identifiers.
 * @property {string[]} [query]       One or more query terms.
 * @property {string[]} [limit]
 */

/**
 * @typedef LookupCondition
 *
 * @property {Object.<string,(boolean|undefined)>} [or]
 * @property {Object.<string,(boolean|undefined)>} [and]
 */

/**
 * @typedef LookupTerms
 *
 * @property {Object.<string,(string|string[])>} [or]
 * @property {Object.<string,(string|string[])>} [and]
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * The set of valid identifier prefixes.
 *
 * @readonly
 * @enum {string}
 */
const ID_TYPES = deepFreeze([
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
const QUERY_TYPES = deepFreeze([
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
const LIMIT_TYPES = deepFreeze([
    // TODO: none yet
]);

/**
 * Each request type and the valid search term prefixes associated with it.
 *
 * @readonly
 * @type {LookupRequestPayload}
 */
const LOOKUP_TYPE = deepFreeze({
    ids:    ID_TYPES,
    query:  QUERY_TYPES,
    limit:  LIMIT_TYPES,
});

const DEF_ID_TYPE     = 'isbn';
const DEF_QUERY_TYPE  = 'keyword';
const DEF_LOOKUP_TYPE = 'query';

/**
 * Default set of characters interpreted as separating terms.
 *
 * @readonly
 * @type {string}
 */
const DEF_SEPARATORS = '|';

/**
 * Selective URL encoding.
 *
 * @readonly
 * @type {{[char: string]: string}}
 */
const CHAR_ENCODE = deepFreeze({
    '"': '%22',
    "'": '%27',
    ':': '%3A'
});

// ============================================================================
// Class LookupRequest
// ============================================================================

/**
 * A lookup request message formed by parsing one or more term strings.
 *
 * @extends ChannelRequest
 * @extends LookupRequestPayload
 */
export class LookupRequest extends ChannelRequest {

    static CLASS_NAME = 'LookupRequest';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank object containing an array value for every key defined by
     * {@link LOOKUP_TYPE}.
     *
     * @readonly
     * @type {LookupRequestPayload}
     */
    static TEMPLATE = deepFreeze(toObject(LOOKUP_TYPE, _key => []));

    // ========================================================================
    // Constants - lookup conditions
    // ========================================================================

    /**
     * A mappings of data field to search term prefix for each grouping of
     * terms. <p/>
     *
     * Bibliographic lookup is permitted if any of the "or" fields have a value
     * -OR- if all of the "and" fields have a value.
     *
     * @readonly
     * @type {LookupTerms}
     */
    static LOOKUP_TERMS = deepFreeze({
        or:  { dc_identifier: '' },
        and: { dc_title: 'title', dc_creator: 'author' },
    });

    /**
     * A table of field name mapped on to lookup prefix.
     *
     * @readonly
     * @type {{[field: string]: string}}
     */
    static LOOKUP_PREFIX = deepFreeze(
        Object.fromEntries(
            Object.values(this.LOOKUP_TERMS).map(
                obj => Object.entries(obj)
            ).flat(1)
        )
    );

    /**
     * For the data() item noting which lookup-related fields have valid
     * values.
     *
     * @readonly
     * @type {string}
     */
    static LOOKUP_CONDITION_DATA = 'lookupCondition';

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {string} */ separators;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {string|string[]|LookupRequest|LookupRequestPayload} [terms]
     * @param {string|string[]} [chars]     Separator character(s).
     */
    constructor(terms, chars) {
        super();
        this.separators   = Array.isArray(chars) ? chars.join('') : chars;
        this.separators ||= DEF_SEPARATORS;
        this.add(terms);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /** @returns {LookupRequestPayload} */
    get parts() { return super.parts }

    get ids()   { return this.parts.ids   || [] }
    get query() { return this.parts.query || [] }
    get limit() { return this.parts.limit || [] }

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

    /**
     * A request object with only the terms that would actually be used for a
     * request.
     *
     * @returns {LookupRequestPayload}
     */
    get requestPayload() {
        const source = isPresent(this.ids) ? { ids: this.ids } : this.parts;
        return $.extend(true, this._blankParts(), source);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Add one or more terms.
     *
     * @param {string|string[]|LookupRequest|LookupRequestPayload} [term]
     * @param {string}                                             [prefix]
     */
    add(term, prefix) {
        if (notDefined(term)) { return }
        const type  = typeof(term);
        const obj   = (type !== 'string') && !Array.isArray(term);
        const value = obj ? term : this.parse(term, prefix);
        if (prefix && !obj) {
            this._warn(`prefix "${prefix}" ignored for ${type} term`);
        }
        super.add(value);
    }

    /**
     * Create a lookup request object from the provided terms.
     *
     * @param {string|string[]} term_values
     * @param {string}          [term_prefix]
     *
     * @returns {LookupRequestPayload}
     */
    parse(term_values, term_prefix) {
        this._debug('parse', term_values);
        const parts = this._blankParts();
        const str   = (typeof term_values === 'string');
        let terms   = str ? term_values.split("\n") : arrayWrap(term_values);

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
        const pairs = terms.map(term => this.extractParts(term)).flat(1);
        pairs.forEach(([prefix, value]) => {
            const term = `${prefix}:${value}`;
            let type;
            $.each(LOOKUP_TYPE, (req_type, prefixes) => {
                if (prefixes.includes(prefix)) {
                    type = req_type;
                }
                return !type; // break loop if type found
            });
            type ||= DEF_LOOKUP_TYPE;
            parts[type].push(term);
        });
        return parts;
    }

    /**
     * Split the terms string into an array of prefix/value pairs.
     *
     * - prefix:value
     * - prefix:'value'     If the value string was single-quoted.
     * - prefix:"value"     If the value string was double-quoted.
     *
     * Terms can be separated by one or more space, tab, '|' characters.
     * Values which contain any of those characters must be quoted, however the
     * quotes are removed from the returned elements.
     *
     * @param {string} terms
     *
     * @returns {[string,string][]}
     *
     * @note The method signature differs from ChannelRequest.extractParts.
     */
    extractParts(terms) {
        this._debug('extractParts', terms);
        const parts = terms.matchAll(this._termMatcher);
        return [...parts].map(part => {
            const prefix = part[2]?.toLowerCase();
            let value =
                part[4] || // value inside double quotes
                part[5] || // value inside single quotes
                part[6];   // value if unquoted
            if (!(value = value?.trim())) {
                return [];
            } else if (value.match(/^\d+$/)) {
                return [(prefix || DEF_ID_TYPE), value];
            } else {
                return [(prefix || DEF_QUERY_TYPE), this._encodeValue(value)];
            }
        });
    }

    // ========================================================================
    // Properties - internal
    // ========================================================================

    get _prefixMatch() { return `[^${this.separators}"']+` }
    get _valueMatch()  { return `[^${this.separators}]+` }
    get _termMatcher() { return this.term_regex ||= this._makeTermMatcher() }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Indicate whether the supplied item is a valid prefix.
     *
     * @param {string} prefix
     *
     * @returns {boolean}
     * @protected
     */
    _validPrefix(prefix) {
        return this.constructor.validPrefix(prefix);
    }

    /**
     * Generate a new empty request payload.
     *
     * @returns {LookupRequestPayload}
     * @protected
     */
    _blankParts() {
        return super._blankParts();
    }

    /**
     * Selectively URL-encode certain value characters.
     *
     * @param {string} value
     *
     * @returns {string}
     * @protected
     */
    _encodeValue(value) {
        return value.replaceAll(/./g, char => CHAR_ENCODE[char] || char);
    }

    /**
     * Generate the matcher for {@link extractParts}.
     *
     * @returns {RegExp}
     * @protected
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

    static get idPrefixes()    { return ID_TYPES }
    static get queryPrefixes() { return QUERY_TYPES }
    static get limitPrefixes() { return LIMIT_TYPES }
    static get allPrefixes()   { return this.prefixes ||= this._prefixList() }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    /**
     * All valid search type prefixes.
     *
     * @returns {string[]}
     * @protected
     */
    static _prefixList() {
        return Object.values(LOOKUP_TYPE).flat();
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
     * Generate an empty lookup conditions object.
     *
     * @returns {LookupCondition}
     */
    static blankLookupCondition() {
        // noinspection JSValidateTypes
        return Object.fromEntries(
            Object.entries(this.LOOKUP_TERMS).map(([logical_op, entry]) => {
                const fields = Object.keys(entry).map(fld => [fld, undefined]);
                return [logical_op, Object.fromEntries(fields)];
            })
        );
    }

    /**
     * Generate a new empty request payload.
     *
     * @returns {LookupRequestPayload}
     */
    static blankParts() {
        return super.blankParts();
    }

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {string|string[]|LookupRequest|LookupRequestPayload} item
     * @param {string|string[]} [chars] Passed to constructor (if required).
     *
     * @returns {LookupRequest}
     */
    static wrap(item, chars) {
        const instance = (item instanceof this);
        if (instance && (isMissing(chars) || (chars === item.separators))) {
            return item;
        } else {
            return new this(item, chars);
        }
    }
}

// app/assets/javascripts/feature/images.js
//
// This supports the ability to asynchronously fill placeholders with images,
// e.g. for thumbnails or cover images.  In the first iterations of the EMMA
// application this was used to acquire thumbnails for Bookshare item listings.
//
// NOTE: Untested in the current version of the application.


import { AppDebug }                       from '../application/debug';
import { appSetup }                       from '../application/setup';
import { Emma }                           from '../shared/assets';
import { HIDDEN, selector, toggleHidden } from '../shared/css';
import { isMissing }                      from '../shared/definitions';
import { secondsSince }                   from '../shared/time';


const MODULE = 'Images';
const DEBUG  = true;

AppDebug.file('feature/images', MODULE, DEBUG);

appSetup(MODULE, function() {

    /**
     * Placeholder elements for images that are to be loaded asynchronously.
     *
     * @type {jQuery}
     */
    const $placeholders = $(`*:not(.complete) > .placeholder:not(${HIDDEN})`);

    // Only perform these actions on the appropriate pages.
    if (isMissing($placeholders)) { return }

    // ========================================================================
    // Constants
    // ========================================================================

    const PLACEHOLDER_CLASS = Emma.Image.placeholder.class;
    const PLACEHOLDER       = selector(PLACEHOLDER_CLASS);

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Load an image asynchronously via the server.
     *
     * @param {Selector} image
     * @param {string}   [source]
     */
    function loadImage(image, source) {
        const func  = 'loadImage';
        const $img  = $(image);
        const src   = source || $img.attr('data-path') || $img.attr('src');
        const url   = urlProxyPath(src);
        const start = Date.now();

        /** @type {string} content */
        let content = undefined;
        let error   = '';

        $.ajax({
            url:      url,
            type:     'GET',
            success:  onSuccess,
            error:    onError,
            complete: onComplete
        });

        /**
         * Create an `<img>` from the supplied data and insert in $element.
         *
         * @param {object}         data
         * @param {string}         _status
         * @param {XMLHttpRequest} _xhr
         */
        function onSuccess(data, _status, _xhr) {
            _debug(`${func}: received`, (data?.length || 0), 'bytes.');
            if (isMissing(data)) {
                error   = 'no data';
            } else {
                content = 'data:image/jpg;base64,' + data;
            }
        }

        /**
         * Accumulate the status failure message.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         * @param {string}         message
         */
        function onError(xhr, status, message) {
            error = `${status}: ${xhr.status} ${message}`;
        }

        /**
         * Actions after the request is completed.
         *
         * @param {XMLHttpRequest} _xhr
         * @param {string}         _status
         */
        function onComplete(_xhr, _status) {
            _debug(`${func}: completed in`, secondsSince(start), 'sec.');
            if (error) {
                console.warn(`${func}: ${url}:`, error);
            } else {
                insertImage(content);
            }
        }

        /**
         * Load the deferred image into its container.
         *
         * @param {string} [data]       Default: content.
         */
        function insertImage(data) {
            const image_content = data || content;

            // Prepare the image container by hiding the placeholder (with an
            // appropriate alt tag for accessibility analyzers that don't
            // ignore hidden images).
            const $container = $img.parent();
            if ($img.is(PLACEHOLDER)) {
                toggleHidden($img, true);
                $img.attr('alt', 'Downloading...'); // TODO: I18n
            } else {
                $container.empty();
            }

            // Insert the new image element.
            const id  = $img.data('id')  || $container.data('id');
            const alt = $img.data('alt') || $container.data('alt');
            makeImage(image_content, alt)
                .attr('id', (id  || imageId(src)))
                .attr('data-turbolinks-permanent', true)
                .appendTo($container);
            $container.addClass('complete');
        }
    }

    /**
     * Request an image via the server.
     *
     * @param {string} url
     *
     * @returns {string}
     */
    function urlProxyPath(url) {
        const encoded_url = encodeURIComponent(url);
        return `/search/image?url=${encoded_url}`;
    }

    /**
     * Generate an element ID from a source URL.
     *
     * @param {string} url
     *
     * @returns {string}
     */
    function imageId(url) {
        const file_name    = url.replace(/^.*\//, '');
        const encoded_name = encodeURIComponent(file_name);
        return `img-${encoded_name}`;
    }

    /**
     * Create a placeholder image element.
     *
     * @returns {jQuery}
     */
    function imagePlaceholder() {
        const src = Emma.Image.placeholder.asset;   // Image source.
        const alt = Emma.Image.placeholder.alt;     // Alt text.
        return makeImage(src, alt).addClass(PLACEHOLDER_CLASS);
    }

    /**
     * Create an image element.
     *
     * @param {string} src
     * @param {string} [alt]
     *
     * @returns {jQuery}
     */
    function makeImage(src, alt) {
        const alt_text = alt || '';
        return $(`<img src="${src}" alt="${alt_text}">`);
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Indicate whether console debugging is active.
     *
     * @returns {boolean}
     */
    function _debugging() {
        return AppDebug.activeFor(MODULE, DEBUG);
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        _debugging() && console.log(`${MODULE}:`, ...args);
    }

    // ========================================================================
    // Actions
    // ========================================================================

    // Download all deferred images.
    $placeholders.each(function() {
        const $image = $(this);
        let src;
        if ((src = $image.attr('data-path'))) {
            _debug('FETCHING IMAGE data-path ==', src);
            loadImage($image, src);
        } else if ((src = $image.attr('src')) && src.match(/^http/)) {
            _debug('REPLACING IMAGE src ==', src);
            // noinspection JSCheckFunctionSignatures
            $image.parent().append(imagePlaceholder());
            loadImage($image, src);
        } else {
            _debug('USING IMAGE src ==', src);
        }
    });

});

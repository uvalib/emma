// app/assets/javascripts/feature/images.js


import { Emma }         from '../shared/assets'
import { selector }     from '../shared/css'
import { isMissing }    from '../shared/definitions'
import { secondsSince } from '../shared/time'


$(document).on('turbolinks:load', function() {

    /**
     * Placeholder elements for images that are to be loaded asynchronously.
     *
     * @type {jQuery}
     */
    let $placeholders = $('*:not(.complete) > .placeholder:not(.hidden)');

    // Only perform these actions on the appropriate pages.
    if (isMissing($placeholders)) { return; }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @readonly
     * @type {boolean}
     */
    const DEBUGGING = true;

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
        let $image  = $(image);
        const src   = source || $image.attr('data-path') || $image.attr('src');
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
         * Create an <img> from the supplied data and insert in $element.
         *
         * @param {object}         data
         * @param {string}         status
         * @param {XMLHttpRequest} xhr
         */
        function onSuccess(data, status, xhr) {
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
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
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
            let image_content = data || content;

            // Prepare the image container by hiding the placeholder (with an
            // appropriate alt tag for accessibility analyzers that don't
            // ignore hidden images).
            let $container = $image.parent();
            if ($image.hasClass(PLACEHOLDER_CLASS)) {
                $image.attr('alt', 'Downloading...'); // TODO: I18n
                $image.addClass('hidden');
            } else {
                $container.empty();
            }

            // Insert the new image element.
            const id  = $image.data('id')  || $container.data('id');
            const alt = $image.data('alt') || $container.data('alt');
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
        return '/bs_api/image?url=' + encodeURIComponent(url);
    }

    /**
     * Generate an element ID from a source URL.
     *
     * @param {string} url
     *
     * @returns {string}
     */
    function imageId(url) {
        const file_name = url.replace(/^.*\//, '');
        return 'img-' + encodeURIComponent(file_name);
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
        return $(`<img alt="${alt || ''}" src="${src}">`);
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        if (DEBUGGING) { console.log(...args); }
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

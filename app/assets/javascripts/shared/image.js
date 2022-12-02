// app/assets/javascripts/shared/image.js


// No imports


// ============================================================================
// Functions
// ============================================================================

/**
 * Encode a raw image string.
 *
 * @param {string} image
 *
 * @returns {string|undefined}
 */
export function encodeImage(image) {
    const start = image?.slice(0,5);
    if (start === 'data:') {
        return image;
    } else if (start) {
        return 'data:image/jpeg;base64,' + window.btoa(image);
    }
}

/**
 * Create an image URI (either as a URL or as an encoded image).
 *
 * @param {string} image
 *
 * @returns {string|undefined}
 */
export function encodeImageOrUrl(image) {
    const start = image?.slice(0,5);
    if (['https', 'http:', 'data:'].includes(start)) {
        return image;
    } else if (start) {
        return encodeImage(image);
    }
}

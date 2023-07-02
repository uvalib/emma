// app/assets/javascripts/feature/fonts.js
//
// Load Typekit fonts, adding the script if it is not already present.


import { AppDebug }    from '../application/debug';
import { presence }    from '../shared/definitions';
import { handleEvent } from '../shared/events';


AppDebug.file('feature/fonts');

const TYPEKIT_HOST = 'use.typekit.net';
const TYPEKIT_URL  = `https://${TYPEKIT_HOST}/tgy5tlj.js`;

const $head   = $('head');
const $script = presence($head.find(`script[src*="/${TYPEKIT_HOST}/"]`)) ||
    $(`<script type="text/javascript" src="${TYPEKIT_URL}">`).appendTo($head);

handleEvent($script, 'readystatechange', loadFonts);
handleEvent($script, 'load',             loadFonts);

function loadFonts() {
    try {
        Typekit.load();
    } catch(error) {
        console.warn('Could not load Typekit:', error.message);
    }
}

// app/assets/javascripts/feature/accessibility.js


import { AppDebug }       from '../application/debug';
import { appSetup }       from '../application/setup';
import { handleKeypress } from '../shared/accessibility';
import { handleEvent }    from '../shared/events';


const MODULE = 'feature/accessibility';

AppDebug.file(MODULE);

appSetup(MODULE, function() {

    const $all_field_sets = $('fieldset[tabindex]').not('[tabindex="-1"]');
    const $field_sets     = $all_field_sets.filter(':visible');
    const $multi_select   = $field_sets.filter('[role="listbox"]');
    const $checkboxes     = $multi_select.find('[type="checkbox"]');

    // ========================================================================
    // Actions
    // ========================================================================

    handleEvent($field_sets, 'keydown', handleKeypress);
    handleEvent($checkboxes, 'keydown', handleKeypress);

});

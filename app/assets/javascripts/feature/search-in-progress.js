// app/assets/javascripts/feature/search-in-progress.js


import { AppDebug }         from '../application/debug';
import { appSetup }         from '../application/setup';
import { Emma }             from '../shared/assets';
import { SearchInProgress } from '../shared/search-in-progress';


const MODULE = 'feature/search-in-progress';

AppDebug.file(MODULE);

appSetup(MODULE, function() {
    const no_on_page_exit = (Emma.RAILS_ENV === 'test');
    SearchInProgress.initialize(no_on_page_exit);
});

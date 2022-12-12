// app/assets/javascripts/feature/search-in-progress.js


import { appSetup }         from '../application/setup'
import { Emma }             from '../shared/assets'
import { SearchInProgress } from '../shared/search-in-progress'


appSetup('feature/search-in-progress', function() {
    const no_on_page_exit = (Emma.RAILS_ENV === 'test');
    SearchInProgress.initialize(no_on_page_exit);
});

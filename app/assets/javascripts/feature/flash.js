// app/assets/javascripts/feature/flash.js


import { AppDebug }                    from '../application/debug';
import { appSetup }                    from '../application/setup';
import { flashInitialize, clearFlash } from '../shared/flash';


const PATH = 'feature/flash';

AppDebug.file(PATH);

appSetup(PATH, () => flashInitialize(), () => clearFlash());

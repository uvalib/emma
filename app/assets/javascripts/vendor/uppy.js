// app/assets/javascripts/vendor/uppy.js
//
// Import Uppy modules currently in use.
//
// To avoid having to edit the import list for "import '../vendor/uppy'",
// constants are defined for each unused module.
//
// NOTE: As far as can be determined, this does not need to be included in the
//  'application.js' manifest.  It can be loaded conditionally only for the few
//  pages that need it.

  import Uppy               from '@uppy/core'
//import AwsS3              from '@uppy/aws-s3'
//import Dashboard          from '@uppy/dashboard'
//import DragDrop           from '@uppy/drag-drop'
  import FileInput          from '@uppy/file-input'
  import Informer           from '@uppy/informer'
  import ProgressBar        from '@uppy/progress-bar'
//import StatusBar          from '@uppy/status-bar'
//import ThumbnailGenerator from '@uppy/thumbnail-generator'
  import XHRUpload          from '@uppy/xhr-upload'

//const Uppy                = () => undefined;
  const AwsS3               = () => undefined;
  const Dashboard           = () => undefined;
  const DragDrop            = () => undefined;
//const FileInput           = () => undefined;
//const Informer            = () => undefined;
//const ProgressBar         = () => undefined;
  const StatusBar           = () => undefined;
  const ThumbnailGenerator  = () => undefined;
//const XHRUpload           = () => undefined;

export {
    Uppy,
    AwsS3,
    Dashboard,
    DragDrop,
    FileInput,
    Informer,
    ProgressBar,
    StatusBar,
    ThumbnailGenerator,
    XHRUpload,
}

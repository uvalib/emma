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

  import { AppDebug } from '../application/debug';

  import * as Uppy          from '@uppy/core';
//import AwsS3              from '@uppy/aws-s3';
//import Box                from '@uppy/box';
//import Dashboard          from '@uppy/dashboard';
//import DragDrop           from '@uppy/drag-drop';
//import Dropbox            from '@uppy/dropbox';
  import FileInput          from '@uppy/file-input';
//import GoogleDrive        from '@uppy/google-drive';
  import Informer           from '@uppy/informer';
//import OneDrive           from '@uppy/onedrive';
  import ProgressBar        from '@uppy/progress-bar';
//import StatusBar          from '@uppy/status-bar';
//import ThumbnailGenerator from '@uppy/thumbnail-generator';
//import Url                from '@uppy/url';
  import XHRUpload          from '@uppy/xhr-upload';

//const Uppy                = undefined;
  const AwsS3               = undefined;
  const Box                 = undefined;
  const Dashboard           = undefined;
  const DragDrop            = undefined;
  const Dropbox             = undefined;
//const FileInput           = undefined;
  const GoogleDrive         = undefined;
//const Informer            = undefined;
  const OneDrive            = undefined;
//const ProgressBar         = undefined;
  const StatusBar           = undefined;
  const ThumbnailGenerator  = undefined;
  const Url                 = undefined;
//const XHRUpload           = undefined;

export {
    Uppy,
    AwsS3,
    Box,
    Dashboard,
    DragDrop,
    Dropbox,
    FileInput,
    GoogleDrive,
    Informer,
    OneDrive,
    ProgressBar,
    StatusBar,
    ThumbnailGenerator,
    Url,
    XHRUpload,
};


AppDebug.file('vendor/uppy');

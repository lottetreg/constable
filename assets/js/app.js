import css from '../css/app.scss';

// Framework JS
import 'phoenix_html';

// Basic AJAX Helper
import './lib/remote-append';

// Bring in jQuery for other modules that rely on it
import $ from 'jquery';
window.jQuery = $;
window.$ = $;

// Set up turbolinks
import TurboLinks from 'turbolinks';
TurboLinks.start();

// Set up local-time
import LocalTime from 'local-time';
LocalTime.start();

// Make the modules available to html pages
import * as commentForm from './components/comment-form';
import * as syntaxHighlighting from './lib/syntax-highlighting';
import * as announcementForm from './components/announcement-form';
import * as announcementFormMobile from './components/announcement-form-mobile';
import * as textareaImageUploader from './lib/textarea-image-uploader';
import * as userAutocomplete from './components/user-autocomplete';

global.constable = global.constable || {
  commentForm,
  syntaxHighlighting,
  announcementForm,
  announcementFormMobile,
  textareaImageUploader,
  userAutocomplete,
};

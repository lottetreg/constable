import Mousetrap from 'mousetrap';
import socket from '../socket';
import { setupImageUploader } from '../lib/textarea-image-uploader';
import { autocompleteUsers } from './user-autocomplete';

const channel = socket.channel('live-html', {});

channel
  .join()
  .receive('ok', (resp) => {
    console.log('Joined successfully', resp);
  })
  .receive('error', (resp) => {
    console.log('Unable to join', resp);
  });

channel.on('new-comment', (payload) => {
  $(
    `[data-announcement-id='${payload.announcement_id}'] .comments-list`
  ).append(payload.comment_html);
});

const resetForm = (form) => form.reset();
const disableForm = (form) => form.children(':input').attr('disabled', 'disabled');
const enableForm = (form) => form.children(':input').removeAttr('disabled');

const SAVE_SHORTCUT = [ 'mod+enter' ];

const initializeForm = (usersForAutoComplete) => {
  setupImageUploader('#comment_body');
  autocompleteUsers('.comment-textarea', usersForAutoComplete);

  Mousetrap.bind(SAVE_SHORTCUT, () => {
    const $form = $('.comment-form');
    $form.submit();
  });
};

export const setupEditForm = (usersForAutoComplete) => {
  initializeForm(usersForAutoComplete);
};

export const setupNewForm = (usersForAutoComplete) => {
  initializeForm(usersForAutoComplete);

  $('.comment-form').on('submit', function(event) {
    event.preventDefault();
    const form = $(this);

    $.ajax({
      type: 'POST',
      url: form.attr('action'),
      data: form.serialize(),
      beforeSend: () => disableForm(form),
    }).done(() => {
      resetForm(form[0]);
      enableForm(form);
    });
  });
};

const refreshMarkdownPreview = (inputSelector) => {
  $(inputSelector).trigger('input');
};

export const setupImageUploader = (selector) => {
  const shuboxOptions = {
    textBehavior: 'append',
    clickable: false,
    s3urlTemplate: '![description of image]({{s3url}})',
    success() {
      refreshMarkdownPreview(selector);
    },
  };

  if (typeof(Shubox) !== 'undefined') {
    new Shubox(selector, shuboxOptions);
  }
};

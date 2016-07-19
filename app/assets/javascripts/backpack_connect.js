$(document).ready(function() {
  // Request permission from the user
  $('#backpack_connect').click(function() {
    var target = $('#backpack_connect');
    OpenBadges.connect({
      callback: target.data('url'),
      scope: ['issue']
    });
  });

  // Issue the current badge
  $('#backpack_issue').click(function () {
    var target = $('#backpack_issue');
    $.ajax({
      url: target.data('url'),
      type: 'GET',
      data: 'todo',
      dataType: 'json',
      error: function (data) {
        alert('Failure: ' + data);
      },
      success: function (data) {
        alert('Success: ' + data);
      }
    });
  });
});

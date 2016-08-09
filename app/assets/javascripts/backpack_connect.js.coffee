$ ->
  # Issue the current badge
  $('#backpack_issue').click ->
    target = $('#backpack_issue')
    $.ajax
      url: target.data('issue-path'),
      type: 'GET',
      data: 'todo',
      dataType: 'json',
      error: (jqXHR, textStatus, errorThrown) ->
        if jqXHR.status == 401
          OpenBadges.connect callback: target.data('connect-url'), scope: ['issue']
      success: (data, textStatus, jsXHR) ->
        alert('Success: ' + data)

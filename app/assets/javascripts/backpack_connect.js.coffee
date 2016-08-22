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
          current_badge = target.data('current-badge')  # redirect to this badge id on callback
          url = target.data('connect-url') + "?current_badge=#{current_badge}&"
          OpenBadges.connect callback: url, scope: ['issue']
        else
          alert('An error occurred. Reason: ' + jqXHR.responseText)
      success: (data, textStatus, jsXHR) ->
        alert('Success: ' + data)

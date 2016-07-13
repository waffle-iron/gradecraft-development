$(document).ready(function() {
  $('#export-badges').click(function() {
    OpenBadges.connect({
      callback: "http://localhost:5000/api/backpack_connect/connect",
      scope: ['issue']
    });
  });
});

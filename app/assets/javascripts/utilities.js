// Matching the main content div to the size of the window
//Initial load of page

$(".make-lizards").dblclick(function() {
  $(".fa").toggleClass("fa-hand-lizard-o");
});

$('.close').click(function() {
    $(".alert-box").slideUp();
});

$( "#tabs" ).tabs({
  event: "click",
  create: function(event, ui) {
    var widget = $(event.target);
    var panel = widget.find(".ui-tabs-panel");
    var activePanelIndex = panel.find(".active").index();
    if (activePanelIndex >= 0) {
      widget.tabs("option", "active", activePanelIndex);
    }
    //sends the user to the right tab if specified through url
    var hash = $.trim( window.location.hash );
    var urlPanelIndex = panel.find(hash).index();
    if (urlPanelIndex >= 0) {
      widget.tabs("option", "active", urlPanelIndex);
    }
  }
});

 $('.froala').froalaEditor({
  key: '6Ud1QBRVCDLPAZMBQ==',
  inlineMode: false,
  heightMin: 200,
  toolbarButtons: [
    'fullscreen', 'bold', 'italic', 'underline', 'strikeThrough',
    'sep', 'blockStyle', 'emoticons', 'insertTable', 'formatOL', 'formatUL','align',
    'outdent', 'indent', 'insertLink', 'undo', 'redo',
    'clearFormatting', 'selectAll', 'html'
  ]
})

// handle 'select all' buttons, used on release grade forms
$(".select-all").click(function(e){
  var $link = $(this);

  e.preventDefault();
  $link.offsetParent().find('input[type="checkbox"]').prop('checked', 'checked').trigger('change');
});

// handle 'select none' button, used on release grade forms
$(".select-none").click(function(e){
 var $link = $(this);

  e.preventDefault();
  $link.offsetParent().find('input[type="checkbox"]').prop('checked', false).trigger('change');

});

$(".assignmentType").collapse({
  show: function() {
    // The context of 'this' is applied to
    // the collapsed details in a jQuery wrapper
    this.slideDown(100);
  },
  hide: function() {
    this.slideUp(100);
  },
  accordion: true,
  persist: true
});

$(".collapseSection").collapse({
  show: function() {
    // The context of 'this' is applied to
    // the collapsed details in a jQuery wrapper
    this.slideDown(100);
  },
  hide: function() {
    this.slideUp(100);
  },
  accordion: true,
  persist: true
});

// Select2 Search forms for group creation
$("#group_student_ids").select2({
  placeholder: "Select Students",
  allowClear: true
});

// Select2 Search forms for team creation
$("#team_student_ids").select2({
  placeholder: "Select Students",
  allowClear: true
});

// Select2 Search forms for anything that has a data-behavior of multi-select
$(document).find("[data-behavior~=multi-select]").select2({
  allowClear: true
});

// Initializing highcharts table data, currently used to display team charts
$('table.highchart').highchartTable();

//Toggle options menu
$(".button-options").click(function(){
    $(this).next('.options-menu').toggle();
});

//Filter content on the student index page table for instructors
$('.button-table-action').click(function() {
  var $tableRows = $('.student-index-table tbody tr');
  var btnId = $(this).attr('id');
  var lowestRank = $tableRows.last().find('td:eq(1)').text();

  $(this).addClass("selected").siblings().removeClass("selected");
  $tableRows.show();
  $tableRows.filter(function() {
    var rank;

    if (btnId === 'btn-top10') {
      rank = $(this).find('td:eq(1)').text();
      return parseInt(rank) > 10;
    } else if (btnId === 'btn-bottom10') {
      rank = $(this).find('td:eq(1)').text();
      return parseInt(rank) <= parseInt(lowestRank) - 10;
    } else if (btnId === 'btn-flagged-students') {
      var flagged = $(this).find('td:eq(0) i').hasClass('flagged');
      return !flagged;
    }
  }).hide();
});

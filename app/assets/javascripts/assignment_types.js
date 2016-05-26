!function($) {
  var init = function() {
    var $form = $('form');

    $form.on('click', '.add-level', function(e) {
      var $wrapper = $('.score-levels');
      var template = $('#score-level-template').html().replace(/child_index/g, $wrapper.children('.score-level').length);
      $wrapper.append(template);
      return false;
    });

    $form.on('click', '.remove-level', function(e) {
      var $link = $(this);
      $link.prev('input.destroy').val(true);
      $link.closest('fieldset.score-level').hide();
      return false;
    });

    $form.on('click', '.add-assignment-score-level', function(e) {
      var $wrapper = $('.assignment-score-levels');
      var template = $('#assignment-score-level-template').html().replace(/child_index/g, $wrapper.children('.assignment-score-level').length);
      $wrapper.append(template);
      return false;
    });

    $form.on('click', '.remove-assignment-score-level', function(e) {
      var $link = $(this);
      $link.prev('input.destroy').val(true);
      $link.closest('fieldset.assignment-score-level').hide();
      return false;
    });

    $form.on('click', '.add-challenge-score-level', function(e) {
      var $wrapper = $('.challenge-score-levels');
      var template = $('#challenge-score-level-template').html().replace(/child_index/g, $wrapper.children('.challenge-score-level').length);
      $wrapper.append(template);
      return false;
    });

    $form.on('click', '.remove-challenge-score-level', function(e) {
      var $link = $(this);
      $link.prev('input.destroy').val(true);
      $link.closest('fieldset.challenge-score-level').hide();
      return false;
    });

    $form.on('click', '.add-unlock-condition', function(e) {
      var $wrapper = $('.unlock-conditions');
      var template = $('#unlock-condition-template').html().replace(/child_index/g, $wrapper.children('.unlock-condition').length);
      $wrapper.append(template);
      return false;
    });

    $form.on('click', '.remove-unlock-condition', function(e) {
      var $link = $(this);
      $link.prev('input.destroy').val(true);
      $link.closest('fieldset.unlock-condition').hide();
      return false;
    });

    $form.on('click', '.add-proposal', function(e) {
      var $wrapper = $('.proposals');
      var template = $('#proposal-template').html().replace(/child_index/g, $wrapper.children('.proposal').length);
      $wrapper.append(template);
      return false;
    });

    $form.on('click', '.remove-proposal', function(e) {
      var $link = $(this);
      $link.prev('input.destroy').val(true);
      $link.closest('fieldset.proposal').hide();
      return false;
    });
  
    // persistence plugin and accordion behaviour
    $(".assignment_type").collapse({
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

    $('.assignments').sortable({
      items: 'div.assignment_type',
      update: function(event){
        $.ajax({          
          url: '/assignment_types/sort',
          type: 'post',
          data: $('.assignments').sortable('serialize'),
          dataType: 'script',
          complete: function(){}
        });
      }
    });

    $('.sort-assignments').sortable({
      update: function(event, ui){
        var element = ui.item[0].parentElement;
        $.ajax({          
          url: '/assignments/sort',
          type: 'post',
          data: $(element).sortable('serialize'),
          dataType: 'script',
          complete: function(event){}
        });
      }
    });
  };
  $(init);
}(jQuery);

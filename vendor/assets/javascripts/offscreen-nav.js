;(function ( $, window, document, undefined ) {
  
  $body = $( 'body' );
  

  $.cbFlyNavLeft = function( options, element ) {
    this.$el = $( element );
    this._init( options );
  };
  
  $.cbFlyNavLeft.defaults = {
    trigger: '.btn-flyout-left-trigger'
    ,cbNavWrapper: '#left-flyout-nav'
    ,cbContentWrapper: '.layout-right-content'
    ,minWidth: 768
	};


  $.cbFlyNavLeft.prototype = {
  
    _init : function( options ) {
      this.options = $.extend({}, $.cbFlyNavLeft.defaults, options);
      
      //Cache elements and intit variables
      this._config();
      
      //Initialize event listenters
      this._initEvents();
    },
    
    _config : function() {
      this.open = false;
      this.copied = false;
      this.windowWith = $(window).width();
      this.subNavOpen = false;
      this.wasOpened = false;
      this.$cbWrap = $('<div class="cbFlyNavLeft-wrap"></div>');
      this.$trigger = $(this.options.trigger);
      this.$regMenus = this.$el.children( 'ul.nav.nav-pill' );
      this.$newMenus = $(this.$el.clone());
      this.$contentMask = $('<a class="nav-flyout-contentmask-left" href="#"></a>');
      this.$navMask = $('<a class="nav-flyout-navmask-left" href="#"></a>');
      this.$openSubnav = "";
    },
    
    _initEvents : function() {
      var self = this; 
      
      self.$trigger.on('click.cbFlyNavLeft', function(e) {
        e.stopPropagation();
        $("body").toggleClass("noscroll");
        if ( !self.open ) {
          if ( !self.copied ) {
            self._copyNav();
          }
          self._openNav();
        }
        else {
          self._closeNav();
        }
        self.wasOpened = true;
        
        //console.log('WasOpened: '+self.wasOpened+ '. Open? '+self.open);
      });
      
      //Hide menu when window is bigger than allowed minWidth
      $(window).on('resize', function() {
        var windowWidth = $(window).width();
        if(self.open && windowWidth > self.options.minWidth){
          self._closeNav();
        }
      });
      
      //Hide menu when body clicked. Usign an a tag to mask content.
      self.$contentMask.on('click.cbFlyNavLeft', function( e ) {
        e.preventDefault();
        $("body").toggleClass("noscroll");
        self._closeNav();
      });
      
      self.$navMask.on('click.cbFlyNavLeft', function( e ) {
        e.preventDefault();
        self._closeSubNav();
      });
      
      //Handle clicks inside menu
      self.$newMenus.on( 'click.cbFlyNavLeft', function( e ) {
        e.stopPropagation();
        var $menu = $(this);
        
        //console.log("Menu clicked");
      });
      
      //Handle menu item clicks
      self.$newMenus.children().find('li').on('click.cbFlyNavLeft', function(e) {
        e.stopPropagation();
        var $item = $(this),
            $subnav = $item.find('ul.subnav');
        
        if ($subnav.length > 0) {
          //item with subnav clicked
          
          //console.log("Item with subnav clicked");

          $subnav.css('height', window.innerHeight);
          self._openSubNav($subnav);
        }
        else {
          //item without subnav clicked
          //console.log("Item without subnav clicked");
        }
      });
      
    },
    
    _copyNav : function() {
      var self = this;
      
      var newWrap = $('<div class="cbFlyNavLeft-wrap"></div>');
      self.$newMenus.children( 'ul.nav.nav-pill' ).each(function() {
        $this = $(this);
        $this.removeClass('nav-pill').addClass('nav-flyout');
      });
            
      $(self.options.cbNavWrapper).prepend(self.$cbWrap.prepend(self.$newMenus));
      self.copied = true;
     
    },
    
    openNav : function() {
      if ( !this.open ) {
        this._openNav();
      }
    },
    
    _openNav : function() {
      var self = this;
        
      $(self.options.cbNavWrapper).addClass('iscbFlyNavLeftActive');
      $(self.options.cbContentWrapper).addClass('iscbFlyNavLeftActive')
      $("body").append(self.$contentMask);

      self.open = true;
    },
    
    closeNav : function() {
      if ( !this.close ) {
        this._closeNav();
      }
    },
    
    _closeNav : function() {
      var self = this;
      
      $(self.options.cbNavWrapper).removeClass('iscbFlyNavLeftActive');
      $(self.options.cbContentWrapper).removeClass('iscbFlyNavLeftActive');
      
      if(self.subNavOpen) {
        self._closeSubNav();
      }
      self.$contentMask.detach();

      self.open = false;
    },
    
    _openSubNav : function($subnav) {
      var self = this,
          $parent = $subnav.parent('li');
          
      $subnav.addClass('is-subnav-visible');
      $parent.addClass('is-active');
      self.$newMenus.addClass('is-inactive');
      self.$cbWrap.append(self.$navMask);
      
      $subnav.on('click.cbFlyNavLeft', function(e) {
        e.stopPropagation();
      });
      
      self.$openSubnav = $subnav;
      self.subNavOpen = true;
    },

    _closeSubNav : function() {
      var self = this,
          $parent = self.$openSubnav.parent('li');
      
      self.$openSubnav.removeClass('is-subnav-visible');
      $parent.removeClass('is-active');
      self.$newMenus.removeClass('is-inactive');
      self.$navMask.detach();
      
      self.$openSubnav.off('click.cbFlyNavLeft');
      
      self.$openSubnav = "";
      self.subNavOpen = false;
    }
  };
  

  $.fn.cbFlyoutLeft = function ( options ) {
    this.each(function() {  
      var instance = $.data( this, 'cbFlyoutLeft' );
      if ( instance ) {
        instance._init();
      }
      else {
        instance = $.data( this, 'cbFlyoutLeft', new $.cbFlyNavLeft( options, this ) );
      }
    });
    
    return this;
  }
  
}(jQuery, window, document));

$(document).ready(function(){
  $('.offscreen-sidebar').cbFlyoutLeft();
});
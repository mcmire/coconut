/*
 jQuery delayed observer
 (c) 2007 - Maxime Haineault (max@centdessin.com)
 http://haineault.com/blog/18/
 
 Special thanks to Stephen Goguen & Tane Piper.
 
 Slight modifications by Elliot Winkler:
 * Don't fire the callback when a non-printable character is pressed
*/

(function() {
  var delayedObserverStack = [];
  var observed;
 
  function delayedObserverCallback(stackPos) {
    observed = delayedObserverStack[stackPos];
    //if (observed.timer) return;
    if (observed.timer) clearTimeout(observed.timer);
   
    observed.timer = setTimeout(function(){
      observed.timer = null;
      observed.callback(observed.obj.val(), observed.obj);
    }, observed.delay * 1000);

    observed.oldVal = observed.obj.val();
  } 
  
  // going by
  // <http://www.cambiaresearch.com/c4/702b8cd1-e5b0-42e6-83ac-25f0306e3e25/Javascript-Char-Codes-Key-Codes.aspx>
  // I think these codes only work when using keyup or keydown
  function isNonPrintableKey(event) {
    var code = event.keyCode;
    return (
      (event.metaKey || event.altKey || event.ctrlKey || event.shiftKey) ||
      (
        (code >= 16 && code <= 46) ||
        (code >= 91 && code <= 93) ||
        (code >= 112 && code <= 145) ||
        // command key on a mac
        (/Mac OS/.test(navigator.userAgent) && code == 224)
      )
    );
  }
 
  jQuery.fn.extend({
    delayedObserver:function(delay, callback){
      $this = $(this);
     
      delayedObserverStack.push({
        obj: $this, timer: null, delay: delay,
        oldVal: $this.val(), callback: callback
      });
       
      stackPos = delayedObserverStack.length-1;
     
      $this.keyup(function(event) {
        if (isNonPrintableKey(event)) return;
        observed = delayedObserverStack[stackPos];
        if (observed.obj.val() == observed.obj.oldVal) return;
        else delayedObserverCallback(stackPos);
      });
    }
  });
})();
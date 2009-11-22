// From http://wiki.script.aculo.us/scriptaculous/show/Cookie
var Cookie = {
  set: function(name, value, daysToExpire) {
    var expire = '';
    if(!daysToExpire) daysToExpire = 365;
    var d = new Date();
    d.setTime(d.getTime() + (86400000 * parseFloat(daysToExpire)));
    expire = 'expires=' + d.toGMTString();
    var path = "path=/"
    // PATCH: Convert value to string
    var cookieValue = escape(name) + '=' + escape(value.toString() || '') + '; ' + path + '; ' + expire + ';';
    return document.cookie = cookieValue;
  },
  get: function(name) {
    var cookie = document.cookie.match(new RegExp('(^|;)\\s*' + escape(name) + '=([^;\\s]+)'));
    if (!cookie) return null;
    var v = cookie[2];
    // PATCH: Type cast boolean values
    if (v == "true") v = true;
    if (v == "false") v = false;
    return v;
  },
  erase: function(name) {
    var cookie = Cookie.get(name) || true;
    Cookie.set(name, '', -1);
    return cookie;
  },
  eraseAll: function() {
    // Get cookie string and separate into individual cookie phrases:
    var cookieString = "" + document.cookie;
    var cookieArray = cookieString.split("; ");

    // Try to delete each cookie:
    for(var i = 0; i < cookieArray.length; ++ i)
    {
      var singleCookie = cookieArray[i].split("=");
      if(singleCookie.length != 2)
        continue;
      var name = unescape(singleCookie[0]);
      Cookie.erase(name);
    }
  },
  accept: function() {
    if (typeof navigator.cookieEnabled == 'boolean') {
      return navigator.cookieEnabled;
    }
    Cookie.set('_test', '1');
    return (Cookie.erase('_test') === '1');
  },
  exists: function(cookieName) {
    var cookieValue = Cookie.get(cookieName);
    // PATCH: Don't return false if cookieValue is false
    if(cookieValue == null) return false;
    return cookieValue.toString() != "";
  }
};

var oldDualScroll;

function onScrollTextarea(event) {
  $("#preview_area").attr("scrollTop", this.scrollTop);
}
function onScrollPreview(event) {
  $("#textarea").attr("scrollTop", this.scrollTop);
}
function toggleDualScroll(event) {
  Cookie.get("dualScroll") ? disableDualScroll() : enableDualScroll();
  if (event) event.preventDefault();
}
function enableDualScroll() {
  $("#textarea").scroll(onScrollTextarea);
  $("#preview_area").scroll(onScrollPreview);
  $(".toggle_dual_scroll").html("Disable dual scroll");
  Cookie.set("dualScroll", true, 7);
  debugCookies();
}
function disableDualScroll() {
  $("#textarea").unbind("scroll", onScrollTextarea);
  $("#preview_area").unbind("scroll", onScrollPreview);
  $(".toggle_dual_scroll").html("Enable dual scroll");
  Cookie.set("dualScroll", false, 7);
  debugCookies();
}

function toggleDisplay(event) {
  Cookie.get("displayHoriz") ? changeDisplayToVert() : changeDisplayToHoriz();
  if (event) event.preventDefault();
}
function changeDisplayToVert() {
  $("#textarea_area").removeClass("horiz").addClass("vert");
  $("#preview_area_wrapper").removeClass("horiz").addClass("vert");
  $(".toggle_display").html("Change display to horizontal");
  oldDualScroll = Cookie.get("dualScroll");
  disableDualScroll();
  Cookie.set("displayHoriz", false, 7);
  debugCookies();
}
function changeDisplayToHoriz() {
  $("#textarea_area").removeClass("vert").addClass("horiz");
  $("#preview_area_wrapper").removeClass("vert").addClass("horiz");
  $(".toggle_display").html("Change display to vertical");
  if (oldDualScroll) enableDualScroll();
  Cookie.set("displayHoriz", true, 7);
  debugCookies();
}

function debugCookies() {
  return false;
  $("#debug").show();html("<b>Dual scroll?</b>: "+Cookie.get("dualScroll")+"<br/>"+"<b>Display horizontally?:</b> "+Cookie.get("displayHoriz")+"<br/>"+"<b>Cookies:</b> "+document.cookie);
}

$(function() {
  /*
  $("#textarea").keyup(function(event) {
    var out = "";
    $.each("metaKey,altKey,ctrlKey,shiftKey,keyCode,charCode".split(","), function() {
      out += this + ": " + event[this] + "<br />";
    });
    $("#debug").show().html(out);
  })
  */
  $("#textarea").delayedObserver(2, function(value, element) {
    var p = $("#preview");
    var timer1, timer2;
    $.ajax({
      url: "/pages/preview",
      type: "POST",
      dataType: "html", 
      data: {content: value},
      beforeSend: function(xhr) {
        timer1 = setTimeout(function() {
          $("#preview_loading span").html("Loading...");
          $("#preview_loading").fadeIn("slow");
          timer2 = setTimeout(function() {
            $("#preview_loading span").html("Still loading...");
          }, 15000);
        }, 3000);
      },
      complete: function(xhr, status) {
        if (timer1) clearTimeout(timer1);
        if (timer2) clearTimeout(timer2);
        $("#preview_loading").hide();
        p.html(xhr.responseText);
      }
    })
  });
  
  if (!Cookie.exists("dualScroll")) Cookie.set("dualScroll", true, 7);
  if (!Cookie.exists("displayHoriz")) Cookie.set("displayHoriz", true, 7);
  
  Cookie.get("dualScroll") ? enableDualScroll() : disableDualScroll();
  Cookie.get("displayHoriz") ? changeDisplayToHoriz() : changeDisplayToVert();
  $(".toggle_dual_scroll").click(toggleDualScroll);
  $(".toggle_display").click(toggleDisplay);
  debugCookies();
});
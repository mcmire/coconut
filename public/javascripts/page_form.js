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
  $("#textarea").delayedObserver(0.5, function(value, element) {
    $("#preview").load("/pages/preview", {content: value})
  });
  
  if (!Cookie.exists("dualScroll")) Cookie.set("dualScroll", true, 7);
  if (!Cookie.exists("displayHoriz")) Cookie.set("displayHoriz", true, 7);
  
  Cookie.get("dualScroll") ? enableDualScroll() : disableDualScroll();
  Cookie.get("displayHoriz") ? changeDisplayToHoriz() : changeDisplayToVert();
  $(".toggle_dual_scroll").click(toggleDualScroll);
  $(".toggle_display").click(toggleDisplay);
  debugCookies();
});
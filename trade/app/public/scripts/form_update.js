function updateForm() {
  var isAuction = document.getElementById("selling_mode_auction").checked;
  var isFixed = document.getElementById("selling_mode_fixed").checked;
    
  if(isAuction) {
    document.getElementById("auction_options").style.display = 'block';
  }else{
    document.getElementById("auction_options").style.display = 'none';
  }
}

function domReady () {
  updateForm();
}

function addListener(){
  // Mozilla, Opera, Webkit 
  if ( document.addEventListener ) {
    document.addEventListener( "DOMContentLoaded", function(){
      document.removeEventListener( "DOMContentLoaded", arguments.callee, false);
      domReady();
    }, false );

  // If IE event model is used
  } else if ( document.attachEvent ) {
    // ensure firing before onload
    document.attachEvent("onreadystatechange", function(){
      if ( document.readyState === "complete" ) {
        document.detachEvent( "onreadystatechange", arguments.callee );
        domReady();
      }
    });
  }
}
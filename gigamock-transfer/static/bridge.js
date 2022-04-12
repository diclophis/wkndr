/* */


var textEncoder = new TextEncoder();
var splitScreen = "split-screen";
var wsHtmlUrl = ((window.location.protocol == "https:" ? "wss" : "ws") + "://" + window.location.host + "/ws-html");
var wsMsgpackUrl = ((window.location.protocol == "https:" ? "wss" : "ws") + "://" + window.location.host + "/ws-msgpack");


function download(filename, text) {
  var element = document.createElement('a');
  element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(UTF8ToString(text)));
  element.setAttribute('download', UTF8ToString(filename));

  element.style.display = 'none';
  document.body.appendChild(element);

  element.click();

  document.body.removeChild(element);
}

function byteLength(str) {
  // returns the byte length of an utf8 string
  var s = str.length;
  for (var i=str.length-1; i>=0; i--) {
    var code = str.charCodeAt(i);
    if (code > 0x7f && code <= 0x7ff) s++;
    else if (code > 0x7ff && code <= 0xffff) s+=2;
    if (code >= 0xDC00 && code <= 0xDFFF) i--; //trail surrogate
  }
  return s;
}

window.startConnection = function(mrbPointer, callbackPointer) {
  if (window["WebSocket"]) {
    window.conn = new WebSocket(wsMsgpackUrl);
    window.conn.binaryType = 'arraybuffer';

    //window.fit = new FitAddon();

    //window.addEventListener('resize', function(resizeEvent) {
    //  window.fit.fit();
    //});

    //window.terminal = new Terminal();
    //window.terminal.loadAddon(window.fit);

    //window.terminal.onKey(function(event) {
    //  // put the keycode you copied from the console
    //  if (window.terminal.hasSelection() && event.key === "\u0003") {
    //    return document.execCommand('copy');
    //  } else if (event.key === "\u0016") {
    //    throw "paste-event-bug, snafu";
    //  }
    //});

    //window.terminal.onData(function(termInputData) {
    //  ///////let encIn = textEncoder.encode(termInputData);
    //  ///////console.log(termInputData);
    //  ///////var ptr = allocate(intArrayFromString(encIn), ALLOC_NORMAL);
    //  ///////window.pack_outbound_tty(mrbPointer, callbackPointer, ptr, encIn.length);
    //  /////    //var buf = new ArrayBuffer(termInputData.length);
    //  /////    //var bufView = new Uint8Array(buf);
    //  /////    //for (var i=0; i < length; i++) {
    //  /////    //  var ic = Module.getValue(bytes + (i), 'i8');
    //  /////    //  bufView[i] = ic;
    //  /////    //}
    //  /////    //window.terminal.write(bufView);
    //  ///////var s = "😀";
    //  ///////window.terminal.write(s);
    //  ///////var ptr = allocate(new Uint8Array(s), ALLOC_NORMAL);
    //  ///////console.log(byteLength(s), s.length);
    //  window.pack_outbound_tty(mrbPointer, callbackPointer, termInputData);
    //});

    document.body.addEventListener('paste', (event) => {
      //TODO: !!!
      let paste = (event.clipboardData || window.clipboardData).getData('text');
      console.log(paste);

      //let encPaste = textEncoder.encode(paste);
      //var ptr = allocate(intArrayFromString(encPaste), ALLOC_NORMAL);
      //console.log("wtf paste event", event, byteLength(paste), encPaste.length, paste.length);
      //window.pack_outbound_tty(mrbPointer, callbackPointer, ptr, byteLength(paste));
    });

    //window.terminal.onResize(function(newSize) {
    //  window.resize_tty(mrbPointer, callbackPointer, graphicsContainer.offsetWidth, graphicsContainer.offsetHeight, newSize.rows, newSize.cols);
    //});

    //window.terminal.open(terminalContainer);

    window.conn.onopen = function (event) {
      //window.fit.fit();

      window.onbeforeunload = function() {
        window.conn.onclose = function () {};
        window.conn.close();
      };

      var ptr = allocate(intArrayFromString(window.location.pathname), ALLOC_NORMAL);
      window.socket_connected(mrbPointer, callbackPointer, ptr, window.location.pathname.length);
    };

    window.conn.onclose = function (event) {
      console.log("Connection closed.");
    };

    window.conn.onmessage = function (event) {
      console.log("FOOO got message from server", event);

      var origData = event.data;

      var typedData = new Uint8Array(origData);
      var heapBuffer = Module._malloc(origData.byteLength * typedData.BYTES_PER_ELEMENT);
      Module.HEAPU8.set(typedData, heapBuffer);
      window.handle_js_websocket_event(mrbPointer, callbackPointer, heapBuffer, origData.byteLength);
      //TODO???? Module._free(heapBuffer);

      return 0;
    };

    return addFunction(function(channel, bytes, length) { //IMPL: write_packed_pointer
      switch(channel) {
        case 0:
          //TODO
          //var buf = new ArrayBuffer(length);
          //var bufView = new Uint8Array(buf);
          //for (var i=0; i < length; i++) {
          //  var ic = Module.getValue(bytes + (i), 'i8');
          //  bufView[i] = ic;
          //}
          //window.terminal.write(bufView);
          break;

        case 1:
          var buf = new ArrayBuffer(length);
          var bufView = new Uint8Array(buf);
          for (var i=0; i < length; i++) {
            var ic = Module.getValue(bytes + (i), 'i8');
            bufView[i] = ic;
          }

          window.conn.send(bufView);
          break;
      }
    }, 'viii');
  } else {
    console.log("Your browser does not support WebSockets.");
  }
};

var graphicsContainer = document.getElementById('canvas');
//var terminalContainer = document.getElementById("wkndr-terminal");

if (graphicsContainer) {
  // As a default initial behavior, pop up an alert when webgl context is lost. To make your
  // application robust, you may want to override this behavior before shipping!
  // See http://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.2
  graphicsContainer.addEventListener("webglcontextlost", function(e) { alert('WebGL context lost. You will need to reload the page.'); e.preventDefault(); }, false);

  var Module = {
    arguments: ['--no-server', '--client=' + graphicsContainer.offsetWidth.toString() + 'x' + graphicsContainer.offsetHeight.toString()],
    preRun: [(function() {
      window.handle_js_websocket_event = Module.cwrap(
        'handle_js_websocket_event', 'number', ['number', 'number', 'number', 'number']
      );

      window.pack_outbound_tty = Module.cwrap(
        'pack_outbound_tty', 'number', ['number', 'number', 'string']
      );

      window.socket_connected = Module.cwrap(
        'socket_connected', 'number', ['number', 'number', 'number', 'number']
      );

      window.resize_tty = Module.cwrap(
        'resize_tty', 'number', ['number', 'number', 'number', 'number', 'number', 'number']
      );

      GLFW.exitFullscreen = function() {
        //TODO: replace hack later
      };
    })],
    postRun: [],
    print: (function() {
      return function(text) {
        if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
        console.log(text);
      };
    })(),
    //printErr: function(text) {
    //  if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
    //  console.error(text);
    //},
    canvas: (function() {
      return graphicsContainer;
    })(),
    setStatus: function(text) {
      if (!Module.setStatus.last) Module.setStatus.last = { time: Date.now(), text: '' };
      if (text === Module.setStatus.text) return;
    },
    totalDependencies: 0,
    monitorRunDependencies: function(left) {
      this.totalDependencies = Math.max(this.totalDependencies, left);
      Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies-left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
    }
  };

  //window.onerror = function(event) {
  //  Module.setStatus('Exception thrown, see JavaScript console');
  //  Module.setStatus = function(text) {
  //    if (text) Module.printErr('[post-exception status] ' + text);
  //  };
  //};

  Module.setStatus('Downloading...');
}


window.startLiveConnection = function() {
  if (window["WebSocket"]) {
    window.conn = new WebSocket(wsHtmlUrl);

    window.conn.onopen = function (event) {
      //this is hypertext app port
      //let initialBits = JSON.stringify({
      //  'party': window.location.pathname
      //});
      //let sent = window.conn.send(initialBits);

      console.log("connected", event);
    };

    window.conn.onclose = function (event) {
      console.log("Connection closed.");
    };

    window.conn.onmessage = function (event) {
      var origDataJson = event.data;

      Array.from(document.getElementsByClassName("wkndr-live-container")).forEach(function(liveContainer, index) {
        var origData = JSON.parse(origDataJson);
        
        morphdom(liveContainer.childNodes[0], origData["foo"], {
          onBeforeElUpdated: function(fromEl, toEl) {
            if (toEl.tagName === 'INPUT') {
              if (fromEl.checked) {
                toEl.checked = fromEl.checked;
              } else {
                toEl.value = fromEl.value;
              }
            }
          },

          onNodeAdded: function(node) {
            if (node.nodeName === 'SCRIPT' && node.src) {
              var script = document.createElement('script');
              script.src = node.src;
              node.replaceWith(script)
            }

            return true;
          }
        });
      });
    };
  } else {
    console.log("Your browser does not support WebSockets.");
  }
};


startLiveConnection();
console.log("WTF!!!");

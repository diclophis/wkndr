/* */

//import { Terminal } from 'xterm';

var splitScreen = "split-screen";
var wsUrl = ((window.location.protocol == "https:" ? "wss" : "ws") + "://" + window.location.host + "/ws");
var wsbUrl = ((window.location.protocol == "https:" ? "wss" : "ws") + "://" + window.location.host + "/wsb");

//function str2ab(str) {
//  var buf = new ArrayBuffer(str.length); // 2 bytes for each char
//  var bufView = new Uint8Array(buf);
//
//  for (var i=0, strLen=str.length; i < strLen; i++) {
//    bufView[i] = str.charCodeAt(i);
//  }
//
//  return buf;
//}
function bytesToString (bytes) {
  // https://github.com/mozilla/activity-stream/pull/3101/files
  // NB: This comes from js/src/vm/ArgumentsObject.h ARGS_LENGTH_MAX
  const ARGS_LENGTH_MAX = 500 * 1000;
  let i = 0;
  let str = "";
  let {length} = bytes;
  while (i < length) {
    const start = i;
    i += ARGS_LENGTH_MAX;
    str += String.fromCharCode.apply(null, bytes.slice(start, i));
  }
  return str;
}

window.startConnection = function(mrbPointer, callbackPointer) {
  if (window["WebSocket"]) {
    window.conn = new WebSocket(wsbUrl);
    window.conn.binaryType = 'arraybuffer';

    window.fit = new FitAddon.FitAddon();

      window.addEventListener('resize', function(resizeEvent) {
        window.fit.fit();
      });

    window.terminal = new Terminal();
    window.terminal.loadAddon(window.fit);

    window.terminal.onData(function(termInputData) {
      //console.log("send this to kilo input", termInputData.length, "adasd");

      //var ptr = //allocate(intArrayFromString(termInputData), 'i8*', ALLOC_NORMAL);


      //var ptr = stackAlloc(size);
      //var x = new Uint8Array(Module['HEAPU8'].buffer, ptr, termInputData.length);
      //x.set(intArrayFromString(termInputData));
      //window.pack_outbound_tty(mrbPointer, callbackPointer, ptr, termInputData.length);

      var ptr = allocate(intArrayFromString(termInputData), ALLOC_NORMAL);
      window.pack_outbound_tty(mrbPointer, callbackPointer, ptr, termInputData.length);

      //Module._free(ptr);

    });

      window.terminal.onResize(function(newSize) {
        console.log("kilo resize", newSize);

        window.resize_tty(mrbPointer, callbackPointer, graphicsContainer.offsetWidth, graphicsContainer.offsetHeight, newSize.rows, newSize.cols);
      });

    window.terminal.open(terminalContainer);

    window.conn.onopen = function (event) {

      window.fit.fit();

      //window.terminal.on('binary', function(termInputData) {
      //  console.log(termInputData);
      //});

      window.onbeforeunload = function() {
        window.conn.onclose = function () {};
        window.conn.close();
      };

      
      //var ptr = allocate(window.location.pathname.length, ALLOC_STACK);
      //var ptr = stackAlloc(window.location.pathname.length);
      //var x = new Uint8Array(Module['HEAPU8'].buffer, ptr, window.location.pathname.length);
      //x.set(intArrayFromString(window.location.pathname));
      //window.socket_connected(mrbPointer, callbackPointer, ptr, window.location.pathname.length);

      //var typedData = new Uint8Array(window.location.pathname);
      //var heapBuffer = Module._malloc(window.location.pathname.byteLength * typedData.BYTES_PER_ELEMENT);
      //Module.HEAPU8.set(typedData, heapBuffer);
      //window.socket_connected(mrbPointer, callbackPointer, heapBuffer, typedData.byteLength);
      //Module._free(heapBuffer);

      var ptr = allocate(intArrayFromString(window.location.pathname), ALLOC_NORMAL);
      window.socket_connected(mrbPointer, callbackPointer, ptr, window.location.pathname.length);


    };

    window.conn.onclose = function (event) {
      console.log("Connection closed.");
    };

    window.conn.onmessage = function (event) {
      console.log("got message from server", event);
      var origData = event.data;

      //var sv = new StringView(origData)
      //TODO: debug stringView of raw msg bits

      
      //var typedData = new Uint8Array(origData);
      //var heapBuffer = Module._malloc(origData.byteLength * typedData.BYTES_PER_ELEMENT);
      //Module.HEAPU8.set(typedData, heapBuffer);
      //window.handle_js_websocket_event(mrbPointer, callbackPointer, heapBuffer, typedData.byteLength);
      //Module._free(heapBuffer);

      var ptr = allocate(new Uint8Array(origData), ALLOC_NORMAL);
      window.handle_js_websocket_event(mrbPointer, callbackPointer, ptr, origData.byteLength);
    };

    window.writePackedPointer = addFunction(function(channel, bytes, length) {
      //console.log("wtf", channel, bytes, length)

      //var stringBits = ab2str(bufView);
      //console.log(bufView, buf);

      if (channel == 0) {
        var buf = new ArrayBuffer(length);
        var bufView = new Uint8Array(buf);
        for (var i=0; i < length; i++) {
          var ic = Module.getValue(bytes + (i), 'i8');
          bufView[i] = ic;
        }
        window.terminal.write(bufView);

        ////var str = bytesToString(bufView);
        ////console.log(`foo-${str.length}-bar`);
        ////window.terminal.write(str);
        //window.terminal.write(bufView);
        //var pointer = allocate([0], 'i8', ALLOC_STACK);
        //var _pointer = Module.getValue(bytes, '*');
        // no need to Module._free(_pointer);
        //var text = Module.Pointer_stringify(_pointer);

        //var ttt = intArrayToString(HEAPU8.subarray(bytes, bytes+length));
        //window.terminal.write(ttt);

        //var ttt = Pointer_stringify(bytes);
        //var ttt = UTF8ToString(bytes, length);
        //var ttt = UTF8ToString(bytes);


      } else if (channel == 1) {
        var buf = new ArrayBuffer(length);
        var bufView = new Uint8Array(buf);
        for (var i=0; i < length; i++) {
          var ic = Module.getValue(bytes + (i), 'i8');
          bufView[i] = ic;
        }

        var sent = window.conn.send(buf);
      }

//      if (channel == 0) {
//        //if (document.body.className != splitScreen) {
//        //  document.body.className = splitScreen;
//        //  setTimeout(function() {
//        //    //window.terminal.fit();
//        //  }, 1);
//        //}
//        //var stringBits = ab2str(bufView);
//
//        console.log(stringBits);
//
//        //window.terminal.write(stringBits);
//
//        //window.terminal.writeUtf8(bufView);
//      } else if (channel == 1) {
//        var sent = window.conn.send(buf);
//      }
//
//      //TODO: memory cleanup??????
//      buf = null;
//      bufView = null;
//      return;

    }, 'viii');

    return window.writePackedPointer;
  } else {
    console.log("Your browser does not support WebSockets.");
  }
};

var graphicsContainer = document.getElementById('canvas');
var terminalContainer = document.getElementById("wkndr-terminal");

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
        'pack_outbound_tty', 'number', ['number', 'number', 'number', 'number']
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
        //terminalContainer.innerHTML += (text) + "<br>";
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
    window.conn = new WebSocket(wsUrl);

    window.conn.onopen = function (event) {
      console.log("connected");
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

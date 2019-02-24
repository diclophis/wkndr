/* */

var graphicsContainer = document.getElementById('wkndr-graphics');
// As a default initial behavior, pop up an alert when webgl context is lost. To make your
// application robust, you may want to override this behavior before shipping!
// See http://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.2
graphicsContainer.addEventListener("webglcontextlost", function(e) { alert('WebGL context lost. You will need to reload the page.'); e.preventDefault(); }, false);

function ab2str(buf) {
  return String.fromCharCode.apply(null, buf); //new Uint8Array(buf));
}

function str2ab(str) {
  var buf = new ArrayBuffer(str.length); // 2 bytes for each char
  var bufView = new Uint8Array(buf);

  for (var i=0, strLen=str.length; i < strLen; i++) {
    bufView[i] = str.charCodeAt(i);
  }

  return buf;
}

window.startConnection = function(mrbPointer, callbackPointer) {
  var wsUrl = ((window.location.protocol == "https:" ? "wss" : "ws") + "://" + window.location.host + "/ws");

  if (window["WebSocket"]) {
    window.conn = new WebSocket(wsUrl);
    window.conn.binaryType = 'arraybuffer';

    window.conn.onopen = function (event) {
      console.log("connected");

      var terminalContainer = document.getElementById("wkndr-terminal");

      Terminal.applyAddon(fit);

      window.terminal = new Terminal({cursorBlink: true, scrollback: 100, tabStopWidth: 2});
      window.terminal.open(terminalContainer);

      window.terminal.on('data', function(termInputData) {
        var ptr = allocate(intArrayFromString(termInputData), 'i8', ALLOC_NORMAL);
        window.pack_outbound_tty(mrbPointer, callbackPointer, ptr, termInputData.length);
        Module._free(ptr);
      });

      window.addEventListener('resize', function(resizeEvent) {
        window.terminal.fit();
      });

      window.terminal.on('resize', function(newSize) {
        console.log('onresize2', mrbPointer, callbackPointer);
        window.resize_tty(mrbPointer, callbackPointer, newSize.cols, newSize.rows, graphicsContainer.offsetWidth, graphicsContainer.offsetHeight);
      });

      window.terminal.fit();

      window.onbeforeunload = function() {
        window.conn.onclose = function () {};
        window.conn.close();
      };

      var ptr = allocate(intArrayFromString(window.location.pathname), 'i8', ALLOC_NORMAL);
      window.socket_connected(mrbPointer, callbackPointer, ptr, window.location.pathname.length);
    };

    window.conn.onclose = function (event) {
      console.log("Connection closed.");
    };

    window.conn.onmessage = function (event) {
      var origData = event.data;
      var typedData = new Uint8Array(origData);
      var heapBuffer = Module._malloc(origData.byteLength * typedData.BYTES_PER_ELEMENT);
      Module.HEAPU8.set(typedData, heapBuffer);
      window.debug_print(mrbPointer, callbackPointer, heapBuffer, typedData.byteLength);
      Module._free(heapBuffer);
    };

    window.writePackedPointer = addFunction(function(channel, bytes, length) {
      var buf = new ArrayBuffer(length); // 2 bytes for each char
      var bufView = new Uint8Array(buf);
      for (var i=0; i < length; i++) {
        var ic = getValue(bytes + (i), 'i8');
        bufView[i] = ic;
      }

      if (channel == 0) {
        var stringBits = ab2str(bufView);
        window.terminal.write(stringBits);
      } else if (channel == 1) {
        var sent = window.conn.send(buf);
      }

      //TODO: memory cleanup??????
      buf = null;
      bufView = null;
    }, 'vvi');

    return window.writePackedPointer;
  } else {
    console.log("Your browser does not support WebSockets.");
  }
};

var Module = {
  arguments: ['client', graphicsContainer.offsetWidth.toString(), graphicsContainer.offsetHeight.toString()],
  preRun: [(function() {
    window.debug_print = Module.cwrap(
      'debug_print', 'number', ['number', 'number', 'number', 'number']
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
    };
  })(),
  printErr: function(text) {
    if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
    console.error(text);
  },
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

window.onerror = function(event) {
  Module.setStatus('Exception thrown, see JavaScript console');
  Module.setStatus = function(text) {
    if (text) Module.printErr('[post-exception status] ' + text);
  };
};

Module.setStatus('Downloading...');

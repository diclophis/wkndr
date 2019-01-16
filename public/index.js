/* */

function ab2str(buf) {
  return String.fromCharCode.apply(null, new Uint8Array(buf));
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
  var wsUrl = ("ws://" + window.location.host + "/ws");

  if (window["WebSocket"]) {
    window.conn = new WebSocket(wsUrl);
    window.conn.binaryType = 'arraybuffer';

    window.conn.onopen = function (event) {
      window.terminal = new Terminal({rows: 20, cols: 80});
      window.terminal.open(document.getElementById("terminal"));

      window.terminal.on('data', function(termInputData) {
        var outboudArrayBuffer = str2ab(termInputData);
        var heapBuffer = Module._malloc(outboundArrayBuffer.length * outboudArrayBuffer.BYTES_PER_ELEMENT);
        pack_outbound_tty(outboundArrayBuffer, heapBuffer);
      });

      window.onbeforeunload = function() {
        window.conn.onclose = function () {};
        window.conn.close();
      };
    };

    window.conn.onclose = function (event) {
      console.log("Connection closed.");
    };

    window.conn.onmessage = function (event) {
      console.log(event.data);
      //var stringBits = ab2str(event.data); //String.fromCharCode.apply(null, new Uint8Array(event.data));

      origData = event.data;
      typedData = new Uint8Array(origData);
      var heapBuffer = Module._malloc(typedData.length * typedData.BYTES_PER_ELEMENT);
      Module.HEAPU8.set(typedData, heapBuffer);
      debug_print(mrbPointer, callbackPointer, heapBuffer, typedData.length);
      Module._free(heapBuffer);
    };

    window.unpack_inbound_tty = function(stringBits) {
      //window.terminal.write(stringBits);
    }
  } else {
    console.log("Your browser does not support WebSockets.");
  }
};

var Module = {
  arguments: ['client'],
  preRun: [(function() {
    //TODO: this goes in the client/shell.js later
    window.debug_print = Module.cwrap(
      'debug_print', 'number', ['number', 'number', 'number', 'number']
    );

    window.pack_outbound_tty = Module.cwrap(
      'pack_outbound_tty', 'number', ['number', 'number']
    );

    console.log(window.debug_print, window.pack_outbound_tty);
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
    var canvas = document.getElementById('canvas');
    // As a default initial behavior, pop up an alert when webgl context is lost. To make your
    // application robust, you may want to override this behavior before shipping!
    // See http://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.2
    canvas.addEventListener("webglcontextlost", function(e) { alert('WebGL context lost. You will need to reload the page.'); e.preventDefault(); }, false);
    return canvas;
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

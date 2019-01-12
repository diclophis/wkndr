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


window.startConnection = function(wsUrl) {
  if (window["WebSocket"]) {
    //TODO: this goes in the client/shell.js later
    //var debug_print = Module.cwrap(
    //  'debug_print', 'number', ['number', 'number']
    //);

    window.conn = new WebSocket(wsUrl);
    window.conn.binaryType = 'arraybuffer';

    window.conn.onopen = function (event) {
      console.log(event);

      window.terminal = new Terminal();
      window.terminal.open(document.getElementById("terminal"));

      window.terminal.on('data', function(termInputData) {
        window.conn.send(str2ab(termInputData));
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
      //console.log(event.data);
      var stringBits = ab2str(event.data); //String.fromCharCode.apply(null, new Uint8Array(event.data));
      window.terminal.write(stringBits);

      /*
      origData = event.data;
      typedData = new Uint8Array(origData);
      var heapBuffer = Module._malloc(typedData.length * typedData.BYTES_PER_ELEMENT);
      Module.HEAPU8.set(typedData, heapBuffer);
      debug_print(heapBuffer, typedData.length);
      Module._free(heapBuffer);
      */
    };
  } else {
    console.log("Your browser does not support WebSockets.");
  }
};

startConnection("ws://10.110.107.195:8000/wss");

//


// system stuff
#include <string.h>


// mruby stuff
#include <mruby.h>
#include <mruby/string.h>


//server stuff
#ifdef TARGET_HEAVY

#include <openssl/sha.h>
#include <b64/cencode.h>

#endif


// (this is a "magic string"), take the SHA-1 hash of the result, and return the base64 encoding of the hash.
#define WS_GUID "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


// error checking
#define E_WEBSOCKET_ERROR mrb_class_get_under(mrb, mrb_module_get(mrb, "WebSocket"), "Error")


// The Sec-WebSocket-Accept part is interesting.
// The server must derive it from the Sec-WebSocket-Key that the client sent.
// To get it, concatenate the client's Sec-WebSocket-Key and WS_GUID together
mrb_value mrb_websocket_create_accept(mrb_state *mrb, mrb_value self) {
  char *client_key;
  mrb_int client_key_len;

  mrb_get_args(mrb, "s", &client_key, &client_key_len);

  if (client_key_len != 24) {
    mrb_raise(mrb, E_WEBSOCKET_ERROR, "wrong client key len");
  }

  uint8_t key_src[60];
  memcpy(key_src, client_key, 24);
  memcpy(key_src+24, WS_GUID, 36);

  mrb_value accept_key = mrb_str_new(mrb, NULL, 28);
  char *c = RSTRING_PTR(accept_key);

#ifdef TARGET_HEAVY
  uint8_t sha1buf[20];
  if (!SHA1((const unsigned char *) key_src, 60, sha1buf)) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "SHA1 failed");
  }

  base64_encodestate s;
  base64_init_encodestate(&s);
  c += base64_encode_block((const char *) sha1buf, 20, c, &s);
  base64_encode_blockend(c, &s);
#endif

  return accept_key;
}

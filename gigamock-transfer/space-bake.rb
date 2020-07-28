a = File.open("/var/tmp/packed-bits", "a")
a.write(MessagePack.pack({"party" => File.open("/var/tmp/chickenwkndr").read}))
a.close

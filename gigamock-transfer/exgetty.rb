#!/usr/bin/env ruby

index_of_dashes = ARGV.index("--")
if index_of_dashes > 0 && (ARGV.length > index_of_dashes)
  username = ARGV[index_of_dashes+1]
else
  puts "please pass username #{ARGV.inspect}"
  exit(1)
end
username = username.gsub(/[^a-z]/, "") #TODO: better username support??
unless username.length > 0
  puts "no good username, please only use a-z #{username.inspect}"
  exit(1)
end

puts "Hello #{username}, checking for account..."

chroot_root = File.join("/", "var", "tmp", "chroot")
user_chroot = File.join(chroot_root, "home", username)
user_home = File.join("/", "home", username)

if Dir.exists?(user_chroot)
  exec("/bin/login", username)
else
  #userdel????
  puts "Please create a new account"
  user_add = ["/usr/sbin/useradd", "--password", "*", "--no-user-group", "--create-home", "--home-dir", user_home, "--skel", "/var/tmp/chroot/etc/skel", "--shell", "/var/tmp/wkndr-chroot.sh",  username]
  unless system(*user_add)
    $stderr.write("bad useradd")
    exit(1)
  end

  unless system("/usr/bin/passwd", username)
    $stderr.write("bad passwd")
    exit(1)
  end

  unless system("/bin/mv", user_home, user_chroot)
    $stderr.write("bad mv")
    exit(1)
  end

  unless system("/bin/mkdir", user_home)
    $stderr.write("bad mkdir")
    exit(1)
  end

  exec("/bin/login", "-f", username)
end

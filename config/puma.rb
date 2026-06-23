dir = "/home/echojs/echojs/"

workers 2
threads 1, 1

preload_app!

bind "unix://#{dir}tmp/sockets/puma.sock"

pidfile "#{dir}tmp/pids/puma.pid"
stdout_redirect "#{dir}log/puma.stdout.log", "#{dir}log/puma.stderr.log", true

This is a simple Unix shell simulator achieved with dart's Process 
I will be attaching the compiled binary of both MAC os and Windows named accordingly. You can run this to simulate all the possible commands without installing dart
If dart is preinstalled, to run the code, its ```dart run bin/unix_shell.dart```
For all the simple command its just like terminal 
For paging:
```paging <fifo or lru>```

For scheduling
```<roundrobin or paging> <count> <only for RR: timeslice>```

For running the mutex and semaphores simulation:
run ```dining``` or ```producerconsumer```

Jobs Foregroud and Background
run ```sleep 10``` to start a foreground job, you can start the same job in the backgroud by running ```sleep 10 &```
If ran on the BG, run ```fg``` to bring it to the foreground or run ```jobs``` to see the running jobs


# RunningProcessSize
Simple command-line utility, that parses MacOS event log for specified period of time (last X seconds/minutes/hours), and displays the list of unique processes present in the period, along with their PID(s), executable path and size.

## How to build
Utility is built with simple shell comand:

```sh
cd RunningProcessSize
swift build
```

## How to run
Utility is run as simple as this (in example the processes are collected for the last 3 minutes):

```sh
swift run RunningProcessSize 3m
``` 

## Sample output
One of possible outputs is shown below (cropped for convenience)

```
 ProcessIDs               ProcessImage                                       ProcessImageSize
----------------------------------------------------------------------------------------------------
 64                       /usr/sbin/systemstats                              3008032
 357                      /usr/sbin/systemsoundserverd                       298000
 217                      /usr/sbin/mDNSResponder                            1869328
 365                      /usr/sbin/filecoordinationd                        140448
 302                      /usr/sbin/distnoted                                343888
 197                      /usr/sbin/coreaudiod                               414352
 118                      /usr/sbin/bluetoothd                               6957488

```

## To Do
- Polish and refactor
- Unit Tests
- Some optimization...


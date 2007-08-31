#!/bin/sh
osascript -e "tell application \"System Preferences\"" -e "reveal pane named \"Growl\"" -e "activate" -e "end tell"



------oo start of event oo------
{ 1 } 'aevt':  misc/mvis (i386){
          return id: 1773666323 (0x69b80013)
     transaction id: 0 (0x0)
  interaction level: 64 (0x40)
     reply required: 1 (0x1)
             remote: 0 (0x0)
      for recording: 0 (0x0)
         reply port: 0 (0x0)
  target:
    { 2 } 'psn ':  8 bytes {
      { 0x0, 0xa59a59 } (System Preferences)
    }
  fEventSourcePSN: { 0x0,0xa6ca6c } (Script Editor)
  optional attributes:
    { 1 } 'reco':  - 1 items {
      key 'csig' - 
        { 1 } 'magn':  4 bytes {
          65536l (0x10000)
        }
    }

  event data:
    { 1 } 'aevt':  - 1 items {
      key '----' - 
        { 1 } 'obj ':  - 4 items {
          key 'form' - 
            { 1 } 'enum':  4 bytes {
              'name'
            }
          key 'want' - 
            { 1 } 'type':  4 bytes {
              'xppb'
            }
          key 'seld' - 
            { 1 } 'utxt':  10 bytes {
              "Growl"
            }
          key 'from' - 
            { -1 } 'null':  null descriptor
        }
    }
}

------oo  end of event  oo------

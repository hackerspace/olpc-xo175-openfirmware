\ The overall firmware revision
macro: FW_PREFIX Q7
macro: FW_MAJOR B
macro: FW_MINOR 16

\ Create a 2-character build/fw-suffix file to personalize your test builds
" fw-suffix" $file-exists?  [if]
   " fw-suffix" $read-file 2 min  " ${FW_MINOR}%s" expand$  sprintf
   " FW_MINOR" $set-macro
[then]

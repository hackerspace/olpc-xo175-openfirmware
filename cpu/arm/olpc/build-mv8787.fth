purpose: Common code for fetching and building the WLAN microcode

\ The macro WLAN_VERSION, and optionally GET_WLAN, must be defined externally

\needs to-file       fload ${BP}/forth/lib/tofile.fth
\needs $md5sum-file  fload ${BP}/forth/lib/md5file.fth

" ${GET_WLAN}" expand$  nip  [if]
   " ${GET_WLAN}" expand$ $sh
[else]

" wget -q -O mv8787.bin 'http://git.marvell.com/?p=mwifiex-firmware.git;a=blob_plain;f=mrvl/sd8787_uapsta.bin;hb=${WLAN_8787_VERSION}'"  expand$ $sh

\ This forces the creation of a .log file, so we don't re-fetch
writing mv8787.version
" ${WLAN_8787_VERSION}"n" expand$  ofd @ fputs
ofd @ fclose

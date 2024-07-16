# discosteganog - hidden messages on discord
*discosteganog* (*disco*rd + *steganog*raphy)<br>
Uses discord formatting to hide an invisible message inside of a normal discord message!<br>
yes, it's not very useful...

## usage
### decoding
run `discosteganog dec` and paste the string in, press enter, and send EOF. (try CTRL-Z on windows, or CTRL-D anywhere else)<br>
it should output the decoded message
### encoding
run `disosteganog enc` and type in the desired message, press enter, and send EOF. (try CTRL-Z on windows, or CTRL-D anywhere else)<br>
it should output the encoded message, just paste this on its own line underneath your message, but be wary of charactar count

## building
simply `zig build`, the compiled file will be in `./zig-out/bin/`<br>
this requires Zig to be installed, of course

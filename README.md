## Why?

On Windows we have the excellent pass client <https://github.com/Baggykiin/pass-winmenu>, but it doesn't quite cover all the management features the original `pass` provides. I've tried all the Linux emulation methods (Cygwin, MSYS2, WSL) but was not happy with any of them. Each has its own quirks and limitations, and I decided I'd rather waste my time learning to do things `The Windows Way` rather than waste it on troubleshooting Linux compatibility layer issues. I'm sticking to Linux solutions on Linux and Windows solutions on Windows. Crazy, right?

## Will this work on Linux?

Yes. I am testing this on Linux, but I'm only _using_ it on Windows. It's quite possible that I might not notice bugs specific to Linux. If you find one, help me out by creating a GitHub issue about it.

## Will this work on "Windows PowerShell" aka PowerShell 5?

Not at the moment. I'm targeting PowerShell Core because that's what I use, and that's the only version available for Linux. For my purposes, I consider "Windows PowerShell" to be "Outdated PowerShell". Anyone can install Core alongside the version built into Windows. Find it here <https://github.com/PowerShell/PowerShell>.

## Can you make it work for "Windows PowerShell"?

Yes. Probably. Maybe even easily. Not a high priority for me to extend support backwards to the old PowerShell though.

## How do you handle editing the password files?

Passwords will be edited with whatever your system uses to open `.txt` files.

Unfortunately there's a problem you should be aware of. At the moment, I simply decrypt the password file to `$ENV:TEMP\Pass\<file>.txt`. This is how the official `pass` client works, but on Linux `/tmp` never touches your disk so files within it do not need to be securely deleted. Windows is a different beast. For now, the solution I have come up with is to overwrite the plaintext file with junk data before deleting it. In future versions I'll support Standard Input/Output streams. Other suggestions welcome.

## Why are the functions in Noun-Verb form? Why doesn't it just work like the original `pass`?

Because PowerShell will make make your life miserable if you don't do things its way. I tried. I did. Well, I guess I am here to do things `The Windows Way` after all...

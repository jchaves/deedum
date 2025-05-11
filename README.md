# DumDeeDum, evolving from deedum

A browser for the gemini protocol.


A [Gemini Protocol](https://geminiprotocol.net/) browser.

Gemini is a new, collaboratively designed internet protocol, which explores the space in between gopher and the web, striving to address (perceived) limitations of one while avoiding the (undeniable) pitfalls of the other.

On android fdroid, play store, builds for ios.
## Development

Build should just require installing [flutter](https://flutter.dev/), connecting an android phone over usb (with developer mode turned on):

```
flutter build apk --debug
flutter install
```

Notes for myself and anyone who might need it:
Right now this code seems to compile only using 
- flutter 2.8.1-stable
- gradle gradle-7.4 (android/gradle/wrapper/gradle-wrapper.properties)

TODO: maybe update all the dependencies and everything so it builds in an up-to-date environment
(to be honest, last thing I want is to waste my time keeping up with android development and their
ever-changing best practices, versions, frameworks...)


I haven't been able to get ios building yet because of xcode / macos version restrictions.


Shoutout to the great client tests here:
gemini://egsam.glv.one (http://github.com/pitr/egsam)

### Test server

It is useful to have a server to test against.
You can run `./server server-files/test.gmi` with pass phrase `test` to spinup a single file `ncat` server (make sure you have it installed).

## Release

You need the signing secrets in the environment (`KEY_JKS`, `KEY_PASSWORD`, `KEY_ALIAS`, `ALIAS_PASSWORD`):

```
source Envfile
./release
```
# Future ?
- zoomable images (should be done, could be better perhaps)
- identities linked to pages should be remembered between sessions ? (should be done?)
- automatically detect if there are ANSI codes and not bother processing a pre-text if not? (should be done)
- Gopher ?
- add some visual feedback on link-ontap ?
- inline images ?
- remember open tabs on exit? (or at least ask when closing with some open) 
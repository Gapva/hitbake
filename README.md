# what is this?
hitbake is a lightning-fast, easy-to-use utility for baking rhythm game hit-sounds.
it allows you to render hit-sounds to an audio file

# who is this for?
this is primarily for rhythm game developers who want to ensure that hit-sounds in their game are always synced properly;
e.g. in games like Spin Rhythm, ADoFaI, Etterna, Beat Saber, etc. where hit-sounds always play on time regardless of when/if the note was hit

while other games like osu!, Sound Space, etc. only play hit-sounds when the player hits the note, the games mentioned above disagree with this method
as they believe hit-sounds should serve as a guide, not a response to user input. hitbake's goal is to appeal to the latter idea

# why would you use this?
to understand why hitbake is useful, we need to first recognize that all current "hit-sound baking" methods are performed at run-time,
and this is done by playing each sound individually for every note

using hitbake, this would happen at runtime, but only once before the chart starts (it's even possible to cache this data),
leading to a considerable performance gain. more info can be found below

### per-note runtime baking (existing method)
| pros | cons |
| ---- | ---- |
| fast load times | hurts performance in note-dense charts (especially with polyphony) |
| no need for caching in any situation, so less disk usage | sounds are not guaranteed to remain in sync during frame dips, lag spikes, etc. |

### pre-chart runtime baking (hitbake method)
| pros | cons |
| ---- | ---- |
| extremely performant since it is pre-rendered | slightly longer load times (can be cached, however, to to speed things up even more |
| sounds are guaranteed to remain in perfect sync even while other performance suffers | can use lots of disk space if cached |

# are there any dependencies?
yes; you simply need [ffmpeg](https://ffmpeg.org/download.html) installed to run the program

# how can i contribute?
first, you'll need to clone this repository:
```
git clone https://github.com/Gapva/hitbake.git && cd hitbake
```

then, ensure that you have the [nim programming language](https://nim-lang.org/) installed.
you'll also need `nimble`, the nim package manager

install the following dependencies:
```
nimble install cligen prettyterm
```

to run hitbake from source, simply run `nim r src/hitbake --help`.

to compile hitbake, run `nim c --outdir:build src/hitbake`.
if you are on linux and want to compile for windows, you will first need the `mingw-w64` package (name may differ depending on your distribution's package manage),
and then you will need to run `nim c -d:mingw --outdir:build hitbake`

after making changes, create a [pull request](https://github.com/Gapva/hitbake/compare)

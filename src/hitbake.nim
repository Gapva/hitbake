import cligen, prettyterm
import std/[strformat, strutils, os, osproc, algorithm, math, times, paths]
import "parsers"/soundspace
import "components"/common

const supportedTargets: seq[string] = @[
  "soundspace",
  "novastra"
]

proc resolveUserPath(inputPath: string): string =
  var p = Path(inputPath)
  p = expandTilde(p)
  
  let normalizedStr = normalizedPath($p)
  
  if not p.isAbsolute:
    result = absolutePath(normalizedStr)
  else:
    result = normalizedStr

proc printTask(task: string, first: bool = false): void =
  var head: string = if first: "\n" else: ""
  stdout.write(&"{head}{task}... ")
  stdout.flushFile()

proc finishTask(final: bool = false): void =
  let tail: string = if final: "\n\n" else: "\n"
  stdout.write(&"{FgBlue}done{FgWhite}{tail}")
  stdout.flushFile()

proc mix*(
  sfxFile: string,
  outputPath: string,
  timestamps: seq[int32]
): void =
  # let startTime: Time = getTime()
  
  printTask("preparing parser", true)
  
  var sortedTimestamps: seq[int32] = timestamps
  sortedTimestamps.sort()
  
  finishTask()
  
  printTask("creating input file list")
  
  let (sfxDurationOutput, sfxDurationCode) = execCmdEx(
    &"""ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "{sfxFile}" """
  )
  
  if sfxDurationCode != 0:
    echo(sty"<red>error</red>: failed to get SFX duration")
    quit(1)
  
  let sfxDurationSec: float = parseFloat(sfxDurationOutput.strip())
  let sfxDurationMs: int32 = int32(sfxDurationSec * 1000)
  
  let tempDir: string = getTempDir() / "mix-" & $getTime().toUnix()
  createDir(tempDir)
  
  let rawSfx: string = tempDir / "sfx.raw"
  let extractCmd: string = &"""ffmpeg -i "{sfxFile}" -f s16le -acodec pcm_s16le "{rawSfx}" -y"""
  let (extractOutput {.used.}, extractCode) = execCmdEx(extractCmd, options = {poUsePath})
  
  if extractCode != 0:
    echo(sty"<red>error</red>: failed to extract SFX as raw PCM")
    quit(1)
  
  let (audioInfoOutput, audioInfoCode) = execCmdEx(
    &"""ffprobe -v error -show_entries stream=channels,sample_rate -of default=noprint_wrappers=1:nokey=1 "{sfxFile}" """
  )
  
  if audioInfoCode != 0:
    echo(sty"<red>error</red>: failed to get audio info")
    quit(1)
  
  let audioInfo: seq[string] = audioInfoOutput.strip().split("\n")
  let sampleRate: int = parseInt(audioInfo[0])
  let channels: int = parseInt(audioInfo[1])
  let bytesPerSample: int = 2  # s16le = 2 bytes per sample
  let bytesPerFrame: int = channels * bytesPerSample
  let sfxSamples: int = int(sfxDurationSec * float(sampleRate))
  let sfxBytes: int = sfxSamples * bytesPerFrame
  
  finishTask()
  
  printTask("generating output")
  
  let outputRaw: string = tempDir / "output.raw"
  
  let maxTimestamp: int32 = if sortedTimestamps.len > 0: sortedTimestamps[^1] else: 0'i32
  let totalDurationMs: int32 = maxTimestamp + sfxDurationMs + 1000  # Add 1 second padding
  let totalSamples: int = int(float(totalDurationMs) / 1000.0 * float(sampleRate))
  let totalBytes: int = totalSamples * bytesPerFrame
  
  let sfxData: string = readFile(rawSfx)
  
  var outputBuffer: string = newString(totalBytes)
  
  let sfxBytesInt: int = sfxBytes
  for ts in sortedTimestamps:
    let startSample: int = int(float(ts) / 1000.0 * float(sampleRate))
    let startByte: int = startSample * bytesPerFrame
    # let endByte: int = min(startByte + sfxBytesInt, totalBytes)
    
    if startByte < totalBytes:
      let copyLen: int = min(sfxBytesInt, totalBytes - startByte)
      if copyLen > 0:
        for i in 0..<copyLen:
          let outputIdx: int = startByte + i
          let sfxIdx: int = i mod sfxData.len
          let outputByte: uint8 = outputBuffer[outputIdx].uint8
          let sfxByte: uint8 = sfxData[sfxIdx].uint8
          let mixed: uint8 = min(255'u8, outputByte + sfxByte)
          outputBuffer[outputIdx] = char(mixed)
  
  writeFile(outputRaw, outputBuffer)
  
  finishTask()
  
  printTask("encoding final output")
  
  let encodeCmd: string = &"""ffmpeg -f s16le -ar {sampleRate} -ac {channels} -i "{outputRaw}" -c:a libmp3lame -q:a 2 "{outputPath}" -y"""
  let (encodeOutput, encodeCode) = execCmdEx(encodeCmd, options = {poUsePath})
  
  try:
    removeDir(tempDir)
  except:
    discard
  
  # let endTime: Time = getTime()
  # let elapsedSeconds: float = (endTime - startTime).inMilliseconds.float / 1000.0
  
  finishTask(true)
  
  if encodeCode != 0:
    echo(sty"<red>error</red>: failed to encode output:", &"\n{encodeOutput}")
    quit(1)
  else:
    echo(sty"<green>success</green>: finished baking hitsounds")

proc main(
  targetFormat: string,
  dataPath: string,
  hitSoundFilePath: string = "hitsound.wav",
  outputNameNoExt: string = "hitsounds"
): void =
  if targetFormat notin supportedTargets:
    echo(sty"<red>error</red>: invalid format: ", targetFormat)
    quit(1)
  
  var myMap: Chart
  let resolvedDataPath: string = resolveUserPath(dataPath)
  let resolvedHitSoundFilePath: string = resolveUserPath(hitSoundFilePath)
  echo(resolvedDataPath)
  echo(resolvedHitSoundFilePath)

  case targetFormat:
  of "sspm":
    myMap = newSsChart(resolvedDataPath)
  
  var msecSeq: seq[int32]
  for note in myMap.noteMarkers:
    msecSeq.add(note.msec)
  let ext: string = if hitSoundFilePath.contains("."): hitSoundFilePath.split('.')[^1] else: "wav"
  let outputNameExt: string = &"{outputNameNoExt}.{ext}"
  
  mix(resolvedHitSoundFilePath, outputNameExt, msecSeq)

when isMainModule:
  const splitChar: string = "\n"
  const targetHelpText = block:
    var formattedTargets: seq[string]
    for rawTarget in supportedTargets:
      formattedTargets.add("\t- " & rawTarget)
    "the name of the target game.\nsupported targets are:\n" &
    formattedTargets.join(splitChar)
  
  dispatch(main, help={
    "targetFormat": targetHelpText,
    "dataPath": "path to the chart data file",
    "hitSoundFilePath": "path to the hit-sound audio file (any format)",
    "outputNameNoExt": "the name of the output mix without any file extension"
  }, short={
    "hitSoundFilePath": 's'
  })

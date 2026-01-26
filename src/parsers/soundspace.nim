# parsing support for sound space (.txt) maps

import std/[strformat, strutils, sequtils]
import "../components"/common

type
  SsNote* = ref object of NoteMarker
    xPos*: float32
    yPos*: float32

  SsChart* = ref object of Chart
    audioId*: string

proc newSsChart*(textDataFilePath: string): SsChart =
  var textDataFile: File
  try:
    textDataFile = open(textDataFilePath, fmRead)
    if textDataFile == nil:
      raise newException(IOError, &"could not open raw map data at {textDataFilePath}")
    
    let fileContent = textDataFile.readAll()
    
    let cleanedContent = fileContent.replace("\n", "")
    
    let allParts = cleanedContent.split(",")
    
    if allParts.len <= 1:
      raise newException(ValueError, &"invalid format: no commas found in {textDataFilePath}")
    
    let audioId: string = allParts[0]
    let noteData = allParts[1..^1]
    
    var noteSeq: seq[SsNote]
    for rawNote in noteData:
      let rawNoteParts = rawNote.split("|")
      
      if rawNoteParts.len < 3:
        raise newException(ValueError, &"invalid note format: {rawNote}")
      
      noteSeq.add(SsNote(
        xPos: parseFloat(rawNoteParts[0]).float32,
        yPos: parseFloat(rawNoteParts[1]).float32,
        msec: parseInt(rawNoteParts[2]).int32
      ))

    let trueSeq: seq[NoteMarker] = noteSeq.mapIt(NoteMarker(msec: it.msec))
    
    return SsChart(audioId: audioId, noteMarkers: trueSeq)
    
  finally:
    if not textDataFile.isNil:
      textDataFile.close()

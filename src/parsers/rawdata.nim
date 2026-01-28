# parsing support for raw data (.csv) timestamps

import std/[strformat, strutils]
import "../components"/common

proc newRawData*(csvFilePath: string, delimiter: string = ","): Chart =
  var csvFile: File
  try:
    csvFile = open(csvFilePath, fmRead)
    if csvFile == nil:
      raise newException(IOError, &"could not open raw map data at {csvFilePath}")
    
    let fileContent: string = csvFile.readAll()
    
    let cleanedContent: string = fileContent.replace("\n", "")
    
    let allParts: seq[string] = cleanedContent.split(delimiter)
    
    if allParts.len <= 1:
      raise newException(ValueError, &"invalid format: no commas found in {csvFilePath}")
    
    var noteSeq: seq[NoteMarker]
    for part in allParts:
      noteSeq.add(NoteMarker(
        msec: parseInt(part).int32)
      )

    return Chart(noteMarkers: noteSeq)

  finally:
    if not csvFile.isNil:
      csvFile.close()

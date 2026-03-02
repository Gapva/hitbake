# parsing support for raw data (.csv) timestamps

import std/[strformat, strutils]
import "../components"/common

proc newRawData*(csvData: string, delimiter: string = ","): Chart =
  var csvFile: File
  var fileContent: string
  
  try:
    csvFile = open(csvData, fmRead)
    if csvFile == nil:
      # treat as actual data
      fileContent = csvData
    else:
      fileContent = csvFile.readAll()
    
    let cleanedContent: string = fileContent.replace("\n", "")
    
    let allParts: seq[string] = cleanedContent.split(delimiter)
    
    if allParts.len <= 1:
      raise newException(ValueError, &"invalid format: no commas found in {csvData}")
    
    var noteSeq: seq[NoteMarker]
    for part in allParts:
      noteSeq.add(NoteMarker(
        msec: parseInt(part).int32)
      )

    return Chart(noteMarkers: noteSeq)

  finally:
    if not csvFile.isNil:
      csvFile.close()

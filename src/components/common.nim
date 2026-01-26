type
  
  NoteMarker* = ref object of RootObj
    msec*: int32
  
  Chart* = ref object of RootObj
    noteMarkers*: seq[NoteMarker]

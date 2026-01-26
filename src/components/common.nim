type
  
  NoteMarker* = ref object of RootObj
    xPos*: float32
    yPos*: float32
    msec*: int32
  
  Chart* = ref object of RootObj
    noteMarkers*: seq[NoteMarker]


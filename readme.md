# Code Explorer

The code explorer is a richer version of the code wheel: http://bl.ocks.org/d/4637444/


Getting there: http://bl.ocks.org/d/4686903/

## Why make a new one?
We need a good way to introduce people to the coding scheme. This introduction should be:
- Simple enough to understand at a glance
- Comprehensive enough to be a stand-alone resource
- Reliable on all modern browsers

No resource like this exists yet. 

## Functional Details

### Visualization
- Like the code wheel, but responsive design rather than loading all at once
- Show text on sections 
- Show fewer levels

### Right Side: Heads-up Display
- Code name, description
- Specific comments applied to groups (eg. Combination of purposes)

### Left Side: Lookahead
- Shows children of hovered section


### Admin
At `/admin`, a user may edit the codes which are displayed on the visualization.


## Implementation Details
- Ruby/Sinatra app
- MongoDB + MongoMapper
- D3.js and jQuery

### Vis
- D3.js
- On click:
  - Adjust existing panels
  - Get data for new panels
  - Draw new panels

### Underlying Code API
- Get/Post to `/code/:code` gives the matching code
- Get/Post to `/query` with params give matching codes to that query
  - Eg. `{ parent: "100" }` returns code who list "100" as their parent.



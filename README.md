# fPix
Tool to generate G-Code producing drilled dot panels from images.
A working implementation of the tool and some description about the project can be found here:
http://www.mathiasbernhard.ch/fpix-pixel-art/

## Folder structure
The files in this repository are split up into **two** main parts:
* src/tool
  * This folder contains the [processingjs](http://processingjs.org) sketch files
  * In order to edit them in the Processing IDE, they have to be in a folder named *fPix_web*
  * The methods defined in these files are described in more detail below
* gui
  * this folder contains the file that actually have to be uploaded to a webserver in order to have the tool run in a browser
  * all the single `*.pde` files within `src/tool` are concatenated into `fPix_web.pde`
  * the `<canvas>`-element in `index.html` loads this file as its `data-processing-sources`
  * the `*.php`-files deal with uploading an image from the users hard drive to the server, displaying all the uploaded images as thumbnails in an `<iframe>` and generating the gCode file and writing it to the server
  
## Description of parts
The presentation slides showed at [Fablab Zurich](http://zurich.fablab.ch/pixelbilder-fur-alle-mathias-bernhard-erklart-fpix) can be found [here](http://issuu.com/mbernhard/docs/fablab_presentation).

The `*.pde` files contain the following parts and methods:

### fPix_web.pde
* definition of global variables
* setup()
* draw()

### Analyse.pde
* calcResult(): main method to recalculate the result given the current state of parameters
  
### Dot.pde
Dot is an inner class defined to contain all the necessary information about one drilled hole (position, depth and whether or not it is to be drilled at all, depending on the threshold)

### Export.pde
Methods to generate and return the gCode as a string. It loops through all the Dots in `myDots` (`ArrayList<ArrayList<Dot>>`)

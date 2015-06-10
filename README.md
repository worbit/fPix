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

#### fPix_web
* definition of global variables
* setup()
* draw()

#### Analyse
* calcResult(): main method to recalculate the result given the current state of parameters
  
#### Dot
Dot is an inner class defined to contain all the necessary information about one drilled hole (position, depth and whether or not it is to be drilled at all, depending on the threshold)

#### Export
Methods to generate and return the gCode as a string. It loops through all the Dots in `myDots` (`ArrayList<ArrayList<Dot>>`)

#### HelperMethods
* calculate average luminosity of an image tile
* make level adjustments (everything below `low` is black and everything above `high` is white)
* scale the image to fill the entire sheet of material, factor returned to set slider value in gui
* ballnose conversion: converts linear grey scales to drilling depths, taking into account the round form of the tool and the area of a circle increasing to the square of the radius
* fromat numbers to strings (digits after comma) for export, can also be used for mm/inch conversion if necessary

#### Patterns
This is where the actual pattern as collection of Dots is calculated. Which of the methods is called depends on the `type` variable, checked in a `switch` case in `Analyse.pde`. Currently, there are four patterns available:
1. getOrthoGrid: calculates an orthogonal (90 degree) grid of points
2. getHoneyGrid: calculates a hexagonal (60 degree) grid of points - as in a honeycomb
3. getPolarGrid: calculates a set of concentric circles
4. getSpiralGrid: calculates one continuous spiral from the inside out

#### Preview
Generates a preview of the calculated pattern as PGraphics object that is then displayed by the `draw` loop and actually shows up in the `<canvas>` on the site. The preview is probably not 100% accuarate compared to the physical result, especially the width and end-to-end-connections of line patterns.

#### UserInteraction
Defined in here are all the methods that are called by the GUI-elements of `index.html` to set and get parameters.
Some of the methods can also be called on `keyPressed` (for testing purpose, without the GUI)

Raytracer written in coffeescript
=================================

works, in console (raytracer.coffee)
and in browser (serve content of browser folder)

Python version taken from: http://www.lshift.net/blog/2008/10/29/toy-raytracer-in-python

speed comparison (time of rendering the scene on my desktop computer):

- pure python 2.7 - ~ 55 seconds
- pypy 1.9 - ~ 3.5 seconds
- node 0.8.21 rendering to file - ~5.5 seconds
- coffeescripte compiled to js browser version - rendering to canvas - ~5.5 seconds

Code is partly tested using Jasmine: SpecRunner.html

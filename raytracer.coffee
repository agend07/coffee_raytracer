fs = require 'fs'

class PpmCanvas
    constructor: (@width=640, @height=480, @fileName='balls.ppm') ->
        array = new Uint8ClampedArray @width * @height * 3
        @buffer = new Buffer array
        
    putInRange: (value) ->
        value = value * 255
        if value < 0 then value = 0
        if value > 255 then value = 255
        value

    plot: (x, y, colour) ->
        [r, g, b] = colour

        index = ((@height - y - 1) * @width + x) * 3

        @buffer[index + 0] = @putInRange r
        @buffer[index + 1] = @putInRange g
        @buffer[index + 2] = @putInRange b

    save: () -> 
        header = new Buffer "P6 #{@width} #{@height} 255\n"
        together = Buffer.concat([header, @buffer])

        fs.writeFile @fileName, together, (err) =>
            if err then throw err
            console.log 'file saved'

class Point
    constructor: (@x=0, @y=0, @z=0) ->

    add: (other) ->
        throw 'other must be a Vector' if other.getType() isnt 'Vector'
        new Point(@x+other.x, @y+other.y, @z+other.z)

    substract: (other) ->
        if other.getType() is 'Point'
            new Vector(@x-other.x, @y-other.y, @z-other.z)
        else
            new Point(@x-other.x, @y-other.y, @z-other.z)

    getType: ->
        'Point'



class Vector extends Point
    add: (other) ->
        new Vector(@x+other.x, @y+other.y, @z+other.z)

    substract: (other) ->
        new Vector(@x-other.x, @y-other.y, @z-other.z)

    magnitude: ->
        Math.sqrt(@x*@x + @y*@y + @z*@z)

    scale: (n) ->
        new Vector @x*n, @y*n, @z*n

    dot: (other) ->
        @x*other.x + @y*other.y + @z*other.z

    cross: (other) ->
        new Vector @y*other.z - @z*other.y, @z*other.x - @x*other.z, @x*other.y - @y*other.x

    normalized: ->
        @scale 1 / @magnitude()

    negated: ->
        @scale -1

    reflectThrough: (normal) ->
        d = normal.scale @dot normal
        @substract(d.scale 2)

    getType: ->
        'Vector'


EPSILON = 0.00001
Vector.ZERO = new Vector(0,0,0)
Vector.RIGHT = new Vector(1,0,0)
Vector.UP = new Vector(0,1,0)
Vector.OUT = new Vector(0,0,1)
Point.ZERO = new Point(0, 0, 0)


addColours = (a, scale, b) ->
    [a[0] + scale*b[0], a[1] + scale*b[1], a[2] + scale*b[2]]


firstIntersection = (intersections) ->
    result = null

    for i in intersections
        candidateT = i[1]
        if candidateT and candidateT > -EPSILON
            if not result or candidateT < result[1]
                result = i

    return result


class Ray
    constructor: (@point, vector) ->
        @vector = vector.normalized()
    
    pointAtTime: (t) ->
        @point.add(@vector.scale t)


class Sphere
    constructor: (@centre, @radius) ->
        throw 'centre must be a point' if @centre.getType() isnt 'Point'

    intersectionTime: (ray) ->
        cp = @centre.substract ray.point
        v = cp.dot ray.vector
        discriminant = (@radius*@radius) - (cp.dot(cp) - v*v)

        if discriminant < 0
            return null
        else
            return v - Math.sqrt discriminant

    normalAt: (p) ->
        (p.substract @centre).normalized()


class Halfspace
    constructor: (@point, normal) ->
        @normal = normal.normalized()

    intersectionTime: (ray) ->
        v = ray.vector.dot @normal
        if v
            return 1 / -v
        else
            return null

    normalAt: (p) ->
        @normal


class SimpleSurface
    constructor: (@baseColour=[1,1,1], @specular=0.2, @lambert=0.6, @ambient=1-@specular-@lambert) ->

    baseColourAt: (p) ->
        return @baseColour

    colourAt: (scene, ray, p, normal) ->
        b = @baseColourAt p
        c = [0, 0, 0]

        if @specular > 0
            reflectedRay = new Ray p, ray.vector.reflectThrough(normal)
            reflectedColour = scene.rayColour reflectedRay
            c = addColours c, @specular, reflectedColour

        if @lambert > 0
            lambertAmount = 0
            for lightPoint in scene.visibleLights(p)
                contribution = (lightPoint.substract p).normalized().dot(normal)
                if contribution > 0
                    lambertAmount = lambertAmount + contribution
                lambertAmount = Math.min.apply null, [1, lambertAmount]
                c = addColours c, @lambert * lambertAmount, b

        if @ambient > 0
            c = addColours c, @ambient, b

        return c


class CheckerboardSurface extends SimpleSurface
    constructor: (@baseColour=[1,1,1], @specular=0.2, @lambert=0.6, @ambient=1-@specular-@lambert) ->
        @otherColour = [0, 0, 0]
        @checkSize = 1

    baseColourAt: (p) ->
        v = p.substract Point.ZERO
        v = v.scale(1/@checkSize)

        temp = Math.round(Math.abs(v.x)) + Math.round(Math.abs(v.y)) + Math.round(Math.abs(v.z))
        if temp % 2 then @baseColour else @otherColour

 
class Scene
    constructor: ->
        @objects = []
        @lightPoints = []
        @position = new Point 0, 1.8, 10
        @lookingAt = Point.ZERO
        @fieldOfView = 45
        @recursionDepth = 0

    moveTo: (point) ->
        @position = point

    lookAt: (point) ->
        @lookingAt = point

    addObject: (object, surface) ->
        @objects.push [object, surface]

    addLight: (point) ->
        @lightPoints.push point

    render: (canvas) ->
        console.log 'Computing field of view'
        fovRadians = Math.PI * (@fieldOfView/2) / 180
        halfWidth = Math.tan fovRadians
        halfHeight = 0.75 * halfWidth
        width = halfWidth * 2
        height = halfHeight * 2
        pixelWidth = width / (canvas.width - 1)
        pixelHeight = height / (canvas.height - 1)

        eye = new Ray @position, @lookingAt.substract @position
        vpRight = eye.vector.cross(Vector.UP).normalized()
        vpUp = vpRight.cross(eye.vector).normalized()

        console.log 'Looping over pixels'

        previousfraction = 0

        for y in [0...canvas.height]
            currentfraction = y / canvas.height
            if currentfraction - previousfraction > 0.05
                console.log "#{Math.round currentfraction * 100} complete"
                previousfraction = currentfraction

            for x in [0...canvas.width]
                xcomp = vpRight.scale(x * pixelWidth - halfWidth)
                ycomp = vpUp.scale(y * pixelHeight - halfHeight)

                ray = new Ray eye.point, eye.vector.add(xcomp).add(ycomp)
                colour = @rayColour ray
                canvas.plot x, y, colour

        console.log 'completed'

    rayColour: (ray) ->
        if @recursionDepth > 3
            return [0, 0, 0]
        
        @recursionDepth++
        intersections = ([object, object.intersectionTime(ray), surface] for [object, surface] in @objects)
        i = firstIntersection intersections

        if not i
            @recursionDepth--
            return [0, 0, 0]
        else
            [object, time, surface] = i
            p = ray.pointAtTime time
            result = surface.colourAt @, ray, p, object.normalAt(p)
            @recursionDepth--
            return result

    lightIsVisible: (l, p) ->
        for [object, surface] in @objects
            t = object.intersectionTime new Ray(p, l.substract p)
            if t and t > EPSILON then false else true

    visibleLights: (p) ->
        result = []
        for l in @lightPoints
            if @lightIsVisible l, p
                result.push l
        result


class RayTracer
    constructor: ->
        @canvas = new PpmCanvas
        @scene = new Scene

        @scene.addLight new Point(30, 30, 10)
        @scene.addLight new Point(-10, 100, 30)
        @scene.lookAt new Point(0, 3, 0)
        @scene.addObject new Sphere(new Point(1, 3, -10), 2), new SimpleSurface([1, 1, 0])

        for y in [0..5]
            centre = new Point -2 + y*1, 4.3, -5 + y 
            surface = new SimpleSurface [y/3, 1-y/3, y/3]
            radius = 0.4
            sphere = new Sphere centre, radius
            @scene.addObject sphere, surface

        @scene.addObject new Halfspace(new Point(0,0,0), Vector.UP), new CheckerboardSurface()

        @scene.render @canvas
        @canvas.save()


raytracer =  new RayTracer

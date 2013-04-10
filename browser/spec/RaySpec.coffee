describe "Point", ->

    point1 = null
    point2 = null

    beforeEach ->
        point1 = new Point 1, 0, 0
        point2 = new Point 0, 1, 0

    it "new point should be 1, 0, 0", ->
        expect(point1).toEqual(new Point 1, 0, 0)

    it "should add vector to point", ->
        v = new Vector 0, 1, 0
        result = point1.add v
        expect(result).toEqual(new Point 1, 1, 0)

    it "should not add 2 points, and throw exception", ->
        expect(-> point1.add point2).toThrow();

    it "should substract 2 points and return vector", ->
        result = point1.substract point2
        expect(result).toEqual(new Vector 1, -1, 0)

    it "should substract vector from point and and return point", ->
        v = new Vector 0, 1, 0
        result = point1.substract v
        expect(result).toEqual(new Point 1, -1, 0)



describe "Vector", ->

    vector1 = null
    vector2 = null
    vector3 = null

    beforeEach ->
        vector1 = new Vector 1, 0, 0
        vector2 = new Vector 3, 0, 1
        vector3 = new Vector 1, 2, 3

    it "new vector should be 1, 0, 0", ->
        expect(vector1).toEqual(new Vector 1, 0, 0)

    it "vector should have magniutude of 1", ->
        expect(vector1.magnitude()).toEqual(1)
        expect(vector2.magnitude()).toBeCloseTo(3.162277, 5);

    it "should scale the vector", ->
        result = vector1.scale 2
        expect(result.magnitude()).toEqual(2)
        expect(result).toEqual(new Vector 2, 0, 0)

    it "should give the dot product", ->
        expect(vector1.dot vector2).toEqual(3)
        expect(vector2.dot vector1).toEqual(3)

    it "should give the cross product", ->
        result = vector1.cross vector2
        expect(result).toEqual(new Vector 0, -1, 0)

        result = vector2.cross vector1
        expect(result).toEqual(new Vector 0, 1, 0)

    it "should normalize vector", ->
        result = vector1.scale 3
        expect(result.magnitude()).toEqual(3)

        result = result.normalized()
        expect(result.magnitude()).toEqual(1)

    it "should nagate vector", ->
        result = vector3.negated()

        expect(result).toEqual(new Vector -1, -2, -3)

    it "should reflect through", ->

        v1 = new Vector 1, 2, 3
        v2 = new Vector 4, 5, 6
        result = v1.reflectThrough v2
        expect(result).toEqual(new Vector -255, -318, -381)

        v1 = new Vector -1, -2, -3
        v2 = new Vector 4, 5, 6
        result = v1.reflectThrough v2
        expect(result).toEqual(new Vector 255, 318, 381)

        v1 = new Vector 1, 1, 1
        v2 = new Vector 4, 5, 6
        result = v1.reflectThrough v2
        expect(result).toEqual(new Vector -119, -149, -179)

        
    it "should reflectThrough Vector.RIGHT", ->
        result = Vector.RIGHT.reflectThrough Vector.UP
        expect(result).toEqual(Vector.RIGHT)


    it "should reflectThrough Vector -1, -1, 0", ->
        v = new Vector -1, -1, 0
        result = v.reflectThrough Vector.UP
        expect(result).toEqual(new Vector -1, 1, 0)


describe "Ray", ->
    point = null
    vector = null
    ray = null

    beforeEach ->
        point = new Point 1, 1, 1
        vector = new Vector 1, 2, 3
        ray = new Ray point, vector

    it "should normalize the vector", ->
        expect(ray.vector.magnitude()).toEqual(1)

    it "should calculate pointAtTime", ->
        result = ray.pointAtTime 10
        expect(result).toEqual(new Point 3.6726124191242437, 6.3452248382484875, 9.017837257372731)


describe "Sphere", ->
    point = null

    beforeEach ->
        point = new Point 1, 1, 1

    it "should create the sphere", ->
        sphere = new Sphere point, 10
        expect(sphere.centre).toEqual(new Point 1, 1, 1)
        expect(sphere.radius).toEqual(10)

    it "should calculate intersectionTime", ->
        sphere = new Sphere point, 10
        ray = new Ray(new Point(1, 2, 3), new Vector(2, 3, 4))

        result = sphere.intersectionTime ray
        expect(result).toEqual(-12.001183441135396)

    it "should calculate normalAt", ->
        sphere = new Sphere point, 10
        point2 = new Point 3, 4, 5

        result = sphere.normalAt point2
        expect(result).toEqual(new Vector 0.3713906763541037, 0.5570860145311556, 0.7427813527082074)
    

describe "Halfspace", ->
    it "should normalize the normal vector", ->
        halfspace = new Halfspace((new Point 1, 1, 1), (new Vector(5, 5, 5)))
        expect(halfspace.normal.magnitude()).toEqual(1)


    it "should calculate intersectionTime", ->
        halfspace = new Halfspace((new Point 1, 1, 1), (new Vector(5, 5, 5)))
        ray = new Ray(new Point(1, 2, 3), new Vector(2, 3, 4))

        result = halfspace.intersectionTime(ray)
        expect(result).toEqual(-1.0363754503432019)


# class Halfspace
#     constructor: (@point, normal) ->
#         @normal = normal.normalized()

#     intersectionTime: (ray) ->
#         v = ray.vector.dot @normal
#         if v
#             return 1 / -v
#         else
#             return null

#     normalAt: (p) ->
#         @normal

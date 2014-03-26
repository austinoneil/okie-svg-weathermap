(include-book "data-structures/structures" :dir :system)
(include-book "io-utilities" :dir :teachpacks) ; for rat->str

(defstructure point x y color (:options :slot-writers)) ; from Delaunay.lisp

; estimate: 12 lines
(defun oppositePoint (point other1 other2)
   (let ((x1 (point-x point))
         (y1 (point-y point))
         (x2 (point-x other1))
         (y2 (point-y other1))
         (x3 (point-x other2))
         (y3 (point-y other2)))
        (if (= x3 x2)
            (point x2 y1 nil) ; line is vertical, don't try to calculate slope
            (let* ((m (/ (- y3 y2) (- x3 x2)))
                   (b (- y2 (* m x2)))
                   (msq (* m m))
                   (oppX (/ (+ (* m y1) x1 (- (* m b))) (+ msq 1)))
                   (oppY (/ (+ (* msq y1) (* m x1) b) (+ msq 1))))
                  (point oppX oppY nil)))))

; estimate: 10 lines
(defun minXY (points)
   (if (consp (cdr points))
       (let* ((point (car points))
              (minRest (minXY (cdr points)))
              (minX (min (point-x point) (point-x minRest)))
              (minY (min (point-y point) (point-y minRest))))
             (point minX minY nil))
       (car points)
  ))

; subtracts the X and Y values of base from every point in points
(defun rebasePoints (points base)
   (if (consp points)
       (let ((pt (car points)))
            (cons (point (- (point-x pt) (point-x base))
                         (- (point-y pt) (point-y base))
                         (point-color pt))
                  (rebasePoints (cdr points) base)))
       nil))

; converts a color (list of 3 RGB components as numbers) to a
; comma-separated RGB string
(defun color->str (color)
   (let ((r (car color))
         (g (cadr color))
         (b (caddr color)))
        (string-append (rat->str r 0)
          (string-append ","
            (string-append (rat->str g 0)
              (string-append "," (rat->str b 0))))))
   )

(defun appendStrings (strings)
   (let ((str (car strings))
         (theRest (cdr strings)))
        (if (consp theRest)
            (string-append str (appendStrings theRest))
            str)))

#| This function returns a string containing a semicolon.
   ACL2 displays all sorts of bugs when the semicolon character
   is used for anything other than comments. Since it doesn't
   interpret semicolons properly in string or character 
   literals, this silly-looking hack is necessary.
|#
(defun semicolon () (coerce (list (code-char 59)) 'string))

(defun svgGradient (point1 point2 letter num)
   (appendStrings
    (list "<linearGradient id=\"fade" letter "-" num "\" " 
          "gradientUnits=\"userSpaceOnUse\" " 
          "x1=\"" (rat->str (point-x point1) 4) "\" "
          "y1=\"" (rat->str (point-y point1) 4) "\" "
          "x2=\"" (rat->str (point-x point2) 4) "\" "
          "y2=\"" (rat->str (point-y point2) 4) "\">"
          "<stop offset=\"0%\" style=\"stop-color:rgb("
          (color->str (point-color point1))
          ")" (semicolon) "\" />"
          "<stop offset=\"100%\" style=\"stop-color:rgb(0,0,0)" (semicolon) "\" />"
          "</linearGradient>"
)))

; est. lines: 10
(defun svgDefsPolygon (point1 point2 point3 num letter)
  (appendStrings (list 
    "<polygon points=\""
      (rat->str (point-x point1) 4) "," (rat->str (point-y point1) 4) " "
      (rat->str (point-x point2) 4) "," (rat->str (point-y point2) 4) " "
      (rat->str (point-x point3) 4) "," (rat->str (point-y point3) 4)
    "\" fill=\"url(#fade" letter "-" num
    ")\" style=\"stroke:none" (semicolon) "stroke-width:0\" id=\"path" letter "-" num "\" />"
)))


; estimated lines: 12
(defun svgDefs (point1 point2 point3 num)
  (appendStrings (list
    "<defs>"
    (svgGradient point1 (oppositePoint point1 point2 point3) "A" num)
    (svgGradient point2 (oppositePoint point2 point1 point3) "B" num)
    (svgGradient point3 (oppositePoint point3 point1 point2) "C" num)
    (svgDefsPolygon point1 point2 point3 num "A")
    (svgDefsPolygon point1 point2 point3 num "B")
    "<filter id=\"Default" num "\">"
    "<feImage xlink:href=\"#pathA-" num "\" result=\"layerA\" x=\"0\" y=\"0\" />"
    "<feImage xlink:href=\"#pathB-" num "\" result=\"layerB\" x=\"0\" y=\"0\" />"
    "<feComposite in=\"layerA\" in2=\"layerB\" operator=\"arithmetic\" "
      "k1=\"0\" k2=\"1.0\" k3=\"1.0\" k4=\"0\" result=\"temp\"/>"
    "<feComposite in=\"temp\" in2=\"SourceGraphic\" operator=\"arithmetic\" "
      "k1=\"0\" k2=\"1.0\" k3=\"1.0\" k4=\"0\"/>"
    "</filter></defs>"
)))
    
; estimated lines: 8
(defun svgTriangle (points num)
   (let* ((base (minXY points))
          (rebasedPoints (rebasePoints points base))
          (point1 (first rebasedPoints))
          (point2 (second rebasedPoints))
          (point3 (third rebasedPoints))
          (num-str (rat->str num 0)))
         (appendStrings (list
           "<g transform=\"translate("
           (rat->str (point-x base) 4) " " (rat->str (point-y base) 4)
           ")\" shape-rendering=\"crispEdges\">"
           (svgDefs point1 point2 point3 num-str)
           "<polygon points=\""
             (rat->str (point-x point1) 4) "," (rat->str (point-y point1) 4) " "
             (rat->str (point-x point2) 4) "," (rat->str (point-y point2) 4) " "
             (rat->str (point-x point3) 4) "," (rat->str (point-y point3) 4) "\" "
           "fill=\"url(#fadeC-" num-str ")\" "
           "filter=\"url(#Default" num-str ")\" "
           "style=\"stroke:none" (semicolon) "stroke-width:0\" />"
           "</g>"
           
))))

; sanity checks for oppositePoint
(oppositePoint (point 0 5 nil) (point -3 1 nil) (point 3 1 nil))
(oppositePoint (point 5 0 nil) (point 1 -3 nil) (point 1 3 nil))

; sanity check for minXY
(minXY (list (point 3 3 nil) (point -3 5 nil) (point 4 0 nil)))

; sanity check for rebasePoints
(let ((lst (list (point 3 3 nil) (point -3 5 nil) (point 4 0 nil))))
     (rebasePoints lst (minXY lst)))

; test/sanity check for svgGradient
;(svgGradient (point 5 0 (list 255 128 0)) (point 1 -3 nil) "A" "1")

; test/sanity check for svgDefsPolygon
(svgDefsPolygon (point 0 5 nil) (point -3 1 nil) (point 3 1 nil) "3" "A")

; test/sanity check for svgDefs
(svgDefs (point 0 5 nil) (point -3 1 nil) (point 3 1 nil) "3")

; test/sanity check for svgTriangle
(svgTriangle (list (point 248 172 (list 255 0 0)) (point 248 220 (list 0 255 0)) (point 192 188 (list 0 0 255))) 3)

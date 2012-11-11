define (require) ->
  $ = require 'jquery'
  marionette = require 'marionette'
  csg = require 'csg'
  THREE = require 'three'
  THREE.CSG = require 'three_csg'
  combo_cam = require 'combo_cam'
  detector = require 'detector'
  stats = require  'stats'
  utils = require 'utils'
  threedView_template = require "text!templates/glThree.tmpl"
  requestAnimationFrame = require 'anim'
  
  #TODO:
  #FIXME: memory leaks: When removing objects from scene do we really need: renderer.deallocateObject(Object); ?
  
  
  #just for testing
  
  class MyAxisHelper
    constructor:(size, xcolor, ycolor, zcolor)->
      geometry = new THREE.Geometry()
      
      geometry.vertices.push(
        new THREE.Vector3(-size or -1, 0, 0 ), new THREE.Vector3( size or 1, 0, 0 ),
        new THREE.Vector3(0, -size or -1, 0), new THREE.Vector3( 0, size or 1, 0 ),
        new THREE.Vector3(0, 0, -size or -1 ), new THREE.Vector3( 0, 0, size or 1 )
        )
        
      geometry.colors.push(
        new THREE.Color( xcolor or 0xffaa00 ), new THREE.Color( xcolor or 0xffaa00 ),
        new THREE.Color( ycolor or 0xaaff00 ), new THREE.Color( ycolor or 0xaaff00 ),
        new THREE.Color( zcolor or 0x00aaff ), new THREE.Color( zcolor or 0x00aaff )
        )
        
      material = new THREE.LineBasicMaterial
        vertexColors: THREE.VertexColors
        #depthTest:false
        linewidth:1
      
      return new THREE.Line(geometry, material, THREE.LinePieces)
  
  
  class GlThreeView extends marionette.ItemView
    template: threedView_template
    ui:
      renderBlock :   "#glArea"
      glOverlayBlock: "#glOverlay" 
      overlayDiv:     "#overlay" 
      
    events:
      #'mousemove'   : 'mousemove'
      #'mouseup'     : 'mouseup'
      #'mousewheel'  : 'mousewheel'
      #'mousedown'   : 'mousedown'
      'contextmenu' : 'rightclick'
      'DOMMouseScroll' : 'mousewheel'
      "mousedown .toggleGrid":          "toggleGrid"
      "mousedown .toggleAxes":          "toggleAxes"
      "mousedown .toggleShadows":       "toggleShadows"
      "mousedown .toggleAA":            "toggleAA"
      "mousedown .toggleAutoUpdate":    "toggleAutoUpdate"
      
    
    ###
    triggers: 
      "mousedown .toggleGrid":    "toggleGrid:mousedown"
      "mousedown .toggleAxes":    "toggleAxes:mousedown"
      "mousedown .toggleShadows": "toggleShadows:mousedown"
      "mousedown .toggleAA":      "toggleAA:mousedown"
    ###  
    
    toggleGrid: (ev)=>
        toggled = @settings.get("showGrid")
        if toggled
          @settings.set("showGrid",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("showGrid",true)
          $(ev.target).removeClass("uicon-off")
        return false
        
     
    toggleAxes:(ev)=>
        toggled = @settings.get("showAxes")
        if toggled
          @settings.set("showAxes",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("showAxes",true)
          $(ev.target).removeClass("uicon-off")
        return false
     
    toggleShadows:(ev)=>
        #FIXME: to deactivate shadows on the plane, regenerate its texture (amongst other things)
        toggled = @settings.get("shadows")
        if toggled
          @settings.set("shadows",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("shadows",true)
          $(ev.target).removeClass("uicon-off")
        return false
            
    toggleAA:(ev)=>
        toggled = @settings.get("antialiasing")
        if toggled
          @settings.set("antialiasing",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("antialiasing",true)
          $(ev.target).removeClass("uicon-off")
        return false
        
    toggleAutoUpdate:(ev)=>
        toggled = @settings.get("autoUpdate")
        if toggled
          @settings.set("autoUpdate",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("autoUpdate",true)
          $(ev.target).removeClass("uicon-off")
        return false
      
    rightclick:(ev)=>
      normalizeEvent(ev)
      x = ev.offsetX
      y = ev.offsetY
      @selectObj(x,y)
      ev.preventDefault()
      return false
      
    mousewheel:(ev)=>
      #fix for firefox scroll
      ev = window.event or ev
      wheelDelta = null
      if ev.originalEvent?
        wheelDelta = if ev.originalEvent.detail? then ev.originalEvent.detail*(-120)
      else
        wheelDelta = ev.wheelDelta
      
      ###
      if wheelDelta > 0
        @controls.zoomOut()
      else 
        @controls.zoomIn()
      ev.preventDefault()
      ev.stopPropagation()
      return false
      ###
      
      
      ###ev = window.event or ev; # old IE support  
      #@controls.onMouseWheel(ev)
      delta = Math.max(-1, Math.min(1, (ev.wheelDelta or -ev.detail)))
      delta*=75
      if delta - @camera.position.z <= 100
        @camera.position.z-=delta
      return false
      ###

    mousemove:(ev)->
      #return false
      ###if @dragStart?
        moveMinMax = 10
        
        @dragAmount=[@dragStart.x-ev.offsetX, @dragStart.y-ev.offsetY]
        #@dragAmount[1]=@height-@dragAmount[1]
        #console.log "bleh #{@dragAmount[0]/500}"
        x_move = Math.max(-moveMinMax, Math.min(moveMinMax, @dragAmount[0]/10))
        y_move = Math.max(-moveMinMax, Math.min(moveMinMax, @dragAmount[1]/10))
        #x_move = (x_move/x_move+0.0001)*moveMinMax
        #y_move = (y_move/y_move+0.0001)*moveMinMax
        #console.log("moving by #{y_move}")
        @camera.position.x+=  x_move #@dragAmount.x/10000
        @camera.position.y-=  y_move#@dragAmount.y/100
        return false
      ###  
    dragstart:(ev)=>
      @dragStart={'x':ev.offsetX, 'y':ev.offsetY}
      
    mouseup:(ev)=>
      #if @dragStart?
      #  @dragAmount=[@dragStart.x-ev.offsetX, @dragStart.y-ev.offsetY]
      #  @dragStart=null
     
      #x = ev.offsetX
      #y = ev.offsetY
      #v = new THREE.Vector3((x/@width)*2-1, -(y/@height)*2+1, 0.5)
      
    mousedown:(ev)=>
      #ev.preventDefault()
      #return false
             
    selectObj:(mouseX,mouseY)=>
      v = new THREE.Vector3((mouseX/@width)*2-1, -(mouseY/@height)*2+1, 0.5)
      @projector.unprojectVector(v, @camera)
      ray = new THREE.Ray(@camera.position, v.subSelf(@camera.position).normalize())
      intersects = ray.intersectObjects(@controller.objects)
      
      reset_col=()=>
        if @current?
          #newMat = new THREE.MeshLambertMaterial
          #  color: 0xCC0000
          #@current.material = newMat
          @current.material = @current.origMaterial
          if @current.cageView?
            @scene.remove @current.cageView
          @current=null
          
      draw_impact=(position)=>
        sprite = new THREE.Sprite(
          map: @particleTexture
          transparent: true
          useScreenCoordinates: false
          scaleByViewport:false)
        sprite.position = position
        @scene.add(sprite)
          
      if intersects? 
        if intersects.length > 0
          #display impact
          #draw_impact(intersects[ 0 ].point)
          if intersects[0].object.name != "workplane"
            if @current != intersects[0].object
              @current = intersects[0].object
              newMat = new  THREE.MeshLambertMaterial
                color: 0xCC0000
              #newMat = new THREE.MeshBasicMaterial({color: 0x808080, wireframe: true, shading:THREE.FlatShading})
              #newMat = new THREE.LineBasicMaterial({color: 0xFFFFFF, lineWidth: 1})
              @current.origMaterial = @current.material
              @current.material = newMat
              @addCage @current
              if @current.cageView?
                @scene.add @current.cageView
          else
            reset_col()
        else
          reset_col()
      else
        reset_col()
      @_render()
    
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindAll()
      @scene.remove(@mesh)
      
      try
        @scene.remove @current.cageView
        @current=null
      
      @controller.objects = []
      @model = newModel
      @bindTo(@model, "change", @modelChanged)
      @fromCsg @model
      
    
    modelChanged:(model, value)=>
      console.log "model changed"
      if @settings.get("autoUpdate")
        @fromCsg @model
        
    settingsChanged:(settings, value)=> 
      console.log "settings changed"
      for key, val of @settings.changedAttributes()
        switch key
          when "renderer"
            delete @renderer
            @init()
            @fromCsg @model
            @render()
          when "autoUpdate"
            if val
              @fromCsg @model
          when "showGrid"
            if val
              @addGrid()
            else
              @removeGrid()
          when "gridSize"
            @removeGrid()
            @addGrid()
          when "gridStep"
            @removeGrid()
            @addGrid()
          when "showAxes"
            if val
              @addAxes()
            else
              @removeAxes()
          when "shadows"
            if not val
              @renderer.clearTarget(@light.shadowMap)
              @fromCsg @model
              @render()
              @renderer.shadowMapAutoUpdate = false
              if @settings.get("showGrid")
                @removeGrid()
                @addGrid()
            else
              @renderer.shadowMapAutoUpdate = true
              @fromCsg @model
              @render()
              if @settings.get("showGrid")
                @removeGrid()
                @addGrid()
            
          when "selfShadows"
            @fromCsg @model
            @render()
            
          when "showStats"
            if val
              @ui.overlayDiv.append(@stats.domElement)
            else
              $(@stats.domElement).remove()
              
          when  "projection"
            if val == "orthographic"
              @camera.toOrthographic()
              #@camera.setZoom(6)
            else
              @camera.toPerspective()
              @camera.setZoom(1)
              
          when "position"
            @setupView(val)
            
            
      @_render()  
       
    constructor:(options, settings)->
      super options
      @settings = options.settings #or new GlViewSettings() #TODO fix this horrible hack
      @app = require 'app'
      
      @bindTo(@model, "change", @modelChanged)
      @app.vent.bind "parseCsgRequest", =>
        @fromCsg @model
      
      
      @stats = new stats()
      @stats.domElement.style.position = 'absolute'
      @stats.domElement.style.top = '30px'
      @stats.domElement.style.zIndex = 100
        
      
      @bindTo(@settings, "change", @settingsChanged)
      #Controls:
      @dragging = false
      ##########
      @width = 800
      @height = 600
      @init()
      
      
    init:()=>
      @renderer=null
      #TODO: do this properly
      @configure(@settings)
      @renderer.shadowMapEnabled = true
      @renderer.shadowMapAutoUpdate = true
      
      @controller = new THREE.Object3D()     
      @controller.name = "picker" 
      @controller.objects = []
      
      @projector = new THREE.Projector()
      @setupScene()
      @setupOverlayScene()
      
      if @settings.get("shadows")
        @renderer.shadowMapAutoUpdate = @settings.get("shadows")
      if @settings.get("showGrid")
        @addGrid()
      if @settings.get("showAxes")
        @addAxes()
      if @settings.get("projection") == "orthographic"
        @camera.toOrthographic()
        @camera.setZoom(6)
      else
        @camera.toPerspective()
      
      val = @settings.get("position")
      @setupView(val)
        
    configure:(settings)=>
      if settings.get("renderer")
          renderer = settings.get("renderer")
          if renderer =="webgl"
            if detector.webgl
              console.log "Gl Renderer"
              @renderer = new THREE.WebGLRenderer 
                clearColor: 0x00000000
                clearAlpha: 0
                antialias: true
              @renderer.clear() 
              @renderer.setSize(@width, @height)
              
              @overlayRenderer = new THREE.WebGLRenderer 
                clearColor: 0x000000
                clearAlpha: 0
                antialias: true
              @overlayRenderer.setSize(350, 250)
            else if not detector.webgl and not detector.canvas
              #TODO: handle this correctly
              console.log("No Webgl and no canvas (fallback) support, cannot render")
            else if not detector.webgl and detector.canvas
              @renderer = new THREE.CanvasRenderer 
                clearColor: 0x00000000
                clearAlpha: 0
                antialias: true
              @renderer.clear() 
              @overlayRenderer = new THREE.CanvasRenderer 
                clearColor: 0x000000
                clearAlpha: 0
                antialias: true
              @overlayRenderer.setSize(350, 250)
              @renderer.setSize(@width, @height)
            else
              console.log("No Webgl and no canvas (fallback) support, cannot render")
          else if renderer =="canvas"
            if detector.canvas
              @renderer = new THREE.CanvasRenderer 
                clearColor: 0x00000000
                clearAlpha: 0
                antialias: true
              @renderer.clear() 
              @overlayRenderer = new THREE.CanvasRenderer 
                clearColor: 0x000000
                clearAlpha: 0
                antialias: true
              @overlayRenderer.setSize(350, 250)
              @renderer.setSize(@width, @height)
            else if not detector.canvas
              #TODO: handle this correctly
              console.log("No canvas support, cannot render")
    
    setupScene:()->
      @viewAngle=45
      ASPECT = @width / @height
      NEAR = 1
      FAR = 10000
      ### 
      @camera =
      new THREE.PerspectiveCamera(
          @viewAngle,
          ASPECT,
          NEAR,
          FAR)
      ###
      @camera =
       new THREE.CombinedCamera(
          @width,
          @height,
          @viewAngle,
          NEAR,
          FAR,
          NEAR,
          FAR)
      #function ( width, height, fov, near, far, orthoNear, orthoFar )
      #function ( @width, @height, @viewAngle, NEAR, FAR, NEAR, FAR ) 
      @camera.position.z = 450
      @camera.position.y = 700
      @camera.position.x = 450
          
      @scene = new THREE.Scene()
      @scene.add(@camera)
      @setupLights()
      
      ###
      xArrow = new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(100,0,0),50, 0xFF7700)
      yArrow = new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(100,0,0),50, 0x77FF00)
      zArrow = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(100,0,0),50, 0x0077FF)
      @scene.add xArrow
      @scene.add yArrow
      @scene.add zArrow
      ###
      
    setupOverlayScene:()->
      #Experimental overlay
      ASPECT = 350 / 250
      NEAR = 1
      FAR = 10000
      @overlayCamera =
        new THREE.PerspectiveCamera(@viewAngle,ASPECT, NEAR, FAR)
      @overlayCamera.position.z = @camera.position.z/3
      @overlayCamera.position.y = @camera.position.y/3
      @overlayCamera.position.x = @camera.position.x/3
      
      @overlayscene = new THREE.Scene()
      @overlayscene.add(@overlayCamera)

    setupLights:()=>
      pointLight =
        new THREE.PointLight(0x333333,5)
      pointLight.position.x = -2200
      pointLight.position.y = -2200
      pointLight.position.z = 3000

      @ambientColor = '0x253565'
      ambientLight = new THREE.AmbientLight(@ambientColor)
      
      spotLight = new THREE.SpotLight( 0xbbbbbb, 2 )    
      spotLight.position.x = 0
      spotLight.position.y = 2000
      spotLight.position.z = 0
      #
      spotLight.castShadow = true
      @light= spotLight 
      @scene.add(ambientLight)
      @scene.add(pointLight)
      @scene.add(spotLight)
      
    setupView:(val)=>
      resetCam=()=>
        @camera.position.z = 0
        @camera.position.y = 0
        @camera.position.x = 0
      switch val
        when 'diagonal'
          @camera.position.z = 450
          @camera.position.y = 700
          @camera.position.x = 450
          @camera.lookAt(@scene.position)
        when 'top'
          resetCam()
          @camera.toTopView()
          @camera.position.y = 700
          #@camera.lookAt(@scene.position)
        when 'bottom'
          resetCam()
          @camera.toBottomView()
          @camera.position.y = -700
          #@camera.lookAt(@scene.position)
        when 'front'
          resetCam()
          @camera.toFrontView()
          @camera.position.z = 800
          @camera.position.x = 0
        when 'back'
          resetCam()
          @camera.toBackView()
          @camera.position.z = -800
          @camera.position.x = 0
        when 'left'
          resetCam()
          @camera.toLeftView()
          @camera.position.z = 0
          @camera.position.x = -800
        when 'right'
          resetCam()
          @camera.toRightView()
          @camera.position.z = 0
          @camera.position.x = 800
      
    addGrid:()=>
      ###
      Adds both grid & plane (for shadow casting), based on the parameters from the settings object
      ###
      if not @grid 
        gridSize = @settings.get("gridSize")
        gridStep = @settings.get("gridStep")
        
        gridGeometry = new THREE.Geometry()
        gridMaterial = new THREE.LineBasicMaterial({ color: 0x888888, opacity: 0.5 })
        
        for i in [-gridSize/2..gridSize/2] by gridStep
          gridGeometry.vertices.push(new THREE.Vector3(-gridSize/2, 0, i))
          gridGeometry.vertices.push(new THREE.Vector3(gridSize/2, 0, i))
          
          gridGeometry.vertices.push(new THREE.Vector3(i, 0, -gridSize/2))
          gridGeometry.vertices.push(new THREE.Vector3(i, 0, gridSize/2))
        @grid = new THREE.Line(gridGeometry, gridMaterial, THREE.LinePieces)
        @scene.add @grid
        
        gridGeometry = new THREE.Geometry()
        gridMaterial = new THREE.LineBasicMaterial({ color: 0xcccccc, opacity: 0.5 })
        
        for i in [-gridSize/2..gridSize/2] by gridStep/10
          gridGeometry.vertices.push(new THREE.Vector3(-gridSize/2, 0, i))
          gridGeometry.vertices.push(new THREE.Vector3(gridSize/2, 0, i))
          
          gridGeometry.vertices.push(new THREE.Vector3(i, 0, -gridSize/2))
          gridGeometry.vertices.push(new THREE.Vector3(i, 0, gridSize/2))
        @subGrid = new THREE.Line(gridGeometry, gridMaterial, THREE.LinePieces)
        @scene.add @subGrid
        
        #######
        planeGeometry = new THREE.PlaneGeometry(-gridSize, gridSize, 5, 5)
        #taken from http://stackoverflow.com/questions/12876854/three-js-casting-a-shadow-onto-a-webpage
        planeFragmentShader = [
            "uniform vec3 diffuse;",
            "uniform float opacity;",

            THREE.ShaderChunk[ "color_pars_fragment" ],
            THREE.ShaderChunk[ "map_pars_fragment" ],
            THREE.ShaderChunk[ "lightmap_pars_fragment" ],
            THREE.ShaderChunk[ "envmap_pars_fragment" ],
            THREE.ShaderChunk[ "fog_pars_fragment" ],
            THREE.ShaderChunk[ "shadowmap_pars_fragment" ],
            THREE.ShaderChunk[ "specularmap_pars_fragment" ],

            "void main() {",

                "gl_FragColor = vec4( 1.0, 1.0, 1.0, 1.0 );",

                THREE.ShaderChunk[ "map_fragment" ],
                THREE.ShaderChunk[ "alphatest_fragment" ],
                THREE.ShaderChunk[ "specularmap_fragment" ],
                THREE.ShaderChunk[ "lightmap_fragment" ],
                THREE.ShaderChunk[ "color_fragment" ],
                THREE.ShaderChunk[ "envmap_fragment" ],
                THREE.ShaderChunk[ "shadowmap_fragment" ],
                THREE.ShaderChunk[ "linear_to_gamma_fragment" ],
                THREE.ShaderChunk[ "fog_fragment" ],

                "gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 - shadowColor.x );",

            "}"

        ].join("\n")

        planeMaterial = new THREE.ShaderMaterial
            uniforms: THREE.ShaderLib['basic'].uniforms,
            vertexShader: THREE.ShaderLib['basic'].vertexShader,
            fragmentShader: planeFragmentShader,
            color: 0x0000FF
        
        @plane = new THREE.Mesh(planeGeometry, planeMaterial)
        @plane.rotation.x = Math.PI/2
        @plane.position.y = -0.01
        @plane.name = "workplane"
        @plane.receiveShadow = true
        
        @scene.add(@plane)
       
    removeGrid:()=>
      if @grid
        @scene.remove @plane
        @scene.remove @grid
        @scene.remove @subGrid
        delete @grid
        delete @subGrid
        delete @plane
      
    addAxes:()->
      @axes = new MyAxisHelper(200,0x666666,0x666666, 0x666666)
      @scene.add(@axes)
      
      @xArrow = new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(0,0,0),50, 0xFF7700)
      @yArrow = new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(0,0,0),50, 0x77FF00)
      @zArrow = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(0,0,0),50, 0x0077FF)
      @overlayscene.add @xArrow
      @overlayscene.add @yArrow
      @overlayscene.add @zArrow
      
      @xLabel=@drawText("X")
      @xLabel.position.set(55,0,0)
      @overlayscene.add(@xLabel)
      
      @yLabel=@drawText("Y")
      @yLabel.position.set(0,0,55)
      @overlayscene.add(@yLabel)
      
      @zLabel=@drawText("Z")
      @zLabel.position.set(0,55,0)
      @overlayscene.add(@zLabel)
      
    removeAxes:()->
      @scene.remove @axes
      
      @overlayscene.remove @xArrow
      @overlayscene.remove @yArrow
      @overlayscene.remove @zArrow
      
      @overlayscene.remove @xLabel
      @overlayscene.remove @yLabel
      @overlayscene.remove @zLabel
      
    addCage:(mesh)=>
      bbox = mesh.geometry.boundingBox
      length = bbox.max.x-bbox.min.x
      width  = bbox.max.y-bbox.min.y
      height = bbox.max.z-bbox.min.z
      
      cageGeo= new THREE.CubeGeometry(length,width,height)
      v=(x,y,z)->
         return new THREE.Vector3(x,y,z)
     
      lineMat = new THREE.LineBasicMaterial({color: 0x808080, lineWidth: 2,wireframe: true})
      lineMat = new THREE.MeshBasicMaterial({color: 0x808080, wireframe: true, shading:THREE.FlatShading})
      cage = new THREE.Mesh(cageGeo, lineMat)
      #cage.type = THREE.Lines
      middlePoint=(geometry)->
        #console.log geometry.boundingBox
        middle  = new THREE.Vector3()
        middle.x  = ( geometry.boundingBox.max.x + geometry.boundingBox.min.x ) / 2
        middle.y  = ( geometry.boundingBox.max.y + geometry.boundingBox.min.y ) / 2
        middle.z  = ( geometry.boundingBox.max.z + geometry.boundingBox.min.z ) / 2
        return middle
      
      delta = middlePoint(mesh.geometry)#.negate();
      #cage.translate(mesh.geometry, delta)
      cage.position = delta
      
      truc = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(-length/2,-width/2,height/2),width,0xFF7700)
      cage.add truc
      mesh.cageView= cage #children = []
      
      
    drawText:(text)=>
      canvas = document.createElement('canvas')
      canvas.width = 640
      canvas.height = 640
      context = canvas.getContext('2d')
      context.font = "17px sans-serif"
      context.fillText(text, canvas.width/2, canvas.height/2)

      texture = new THREE.Texture(canvas)
      texture.needsUpdate = true
      sprite = new THREE.Sprite(
        map: texture
        transparent: false
        useScreenCoordinates: false
        scaleByViewport:false)
      return sprite
    
    setupPickerHelper:()->
      canvas = document.createElement('canvas')
      canvas.width = 100
      canvas.height = 100
      context = canvas.getContext('2d')
  
      PI2 = Math.PI * 2
      context.beginPath()
      context.arc( 0, 0, 1, 0, PI2, true )
      context.closePath()
      context.fill()
      context.fillText("X", 40, 40)

      texture = new THREE.Texture( canvas )
      texture.needsUpdate = true
      @particleTexture = new THREE.Texture(canvas)
      @particleTexture.needsUpdate = true
      @particleMaterial = new THREE.MeshBasicMaterial( { map: texture, transparent: true ,color: 0x000000} );
    
    onResize:()=>
      #console.log("resized")
      
      @width =  $("#glArea").width()
      @height = window.innerHeight-100
      
      #@camera.aspect = @width / @height
      #@camera.updateProjectionMatrix()
      
      @camera.setSize(@width,@height)
      @camera.updateProjectionMatrix()
      
      @renderer.setSize(@width, @height)
      
      @overlayCamera.position.z = @camera.position.z/3
      @overlayCamera.position.y = @camera.position.y/3
      @overlayCamera.position.x = @camera.position.x/3
      
      @_render()
      #console.log @camera.position
      #console.log "width #{width} height #{height}"
    
    onRender:()=>
      selectors = @ui.overlayDiv.children(" .uicons")
      selectors.tooltip()
      
      if @settings.get("showStats")
        @ui.overlayDiv.append(@stats.domElement)
        
      @width = $("#gl").width()
      @height = window.innerHeight-100#$("#gl").height()
     
      #@camera.aspect = @width / @height
      #@camera.updateProjectionMatrix()
      @camera.setSize(@width,@height)
      @camera.updateProjectionMatrix()
      @renderer.setSize(@width, @height)
      
      #FIXME: remove this totally random stuff
      @overlayCamera.position.z = @camera.position.z/3
      @overlayCamera.position.y = @camera.position.y/3
      @overlayCamera.position.x = @camera.position.x/3
            
      @_render()
      
      
      @$el.resize @onResize
      window.addEventListener('resize', @onResize, false)
      ##########
      
      container = $(@ui.renderBlock)
      container.append(@renderer.domElement)
      @controls = new THREE.TrackballControls(@camera, @el)
      @controls.autoRotate = false
        
      #OrbitControls
      ###TrackballControls###
      
      @controls.rotateSpeed = 1.8
      @controls.zoomSpeed = 4.2
      @controls.panSpeed = 1.8

      @controls.noZoom = false
      @controls.noPan = false

      @controls.staticMoving = true
      @controls.dynamicDampingFactor = 0.3
      
      @controls.addEventListener( 'change', @_render )
      
      ########
      container2 = $(@ui.glOverlayBlock)
      container2.append(@overlayRenderer.domElement)
      @overlayControls = new THREE.TrackballControls(@overlayCamera, @el)
      @overlayControls.autoRotate = false
      @overlayControls.userZoomSpeed=0
      
      @overlayControls.rotateSpeed = 1.8
      @overlayControls.zoomSpeed = 0
      @overlayControls.panSpeed = 0

      @overlayControls.noZoom = false
      @overlayControls.noPan = false

      @overlayControls.staticMoving = true
      @overlayControls.dynamicDampingFactor = 0.3
      
      @animate()
    
    _render:()=>
      @renderer.render(@scene, @camera)
      @overlayRenderer.render(@overlayscene, @overlayCamera)
      
      if @settings.get("showStats")
        @stats.update()
      
    animate:()=>
      #@camera.lookAt(@scene.position)
      @controls.update()
      
     #@overlayCamera.lookAt(@overlayscene.position)
      @overlayControls.update()

      requestAnimationFrame(@animate)
    
    toCsgTest:(mesh)->
      csgResult = THREE.CSG.toCSG(mesh)
      if csgResult?
        console.log "CSG conversion result ok:"
      
    fromCsg:(csg)=>
      try
        app = require 'app'
        resultCSG = app.csgProcessor.processScript(@model.get("content"))
        @model.csg = resultCSG #FIXME: remove this at all costs (needs overall reorganization perhaps), but a view should not modify a model like this ? or should it?
        
        geom = THREE.CSG.fromCSG(resultCSG)
        
        mat = new THREE.MeshBasicMaterial({color: 0xffffff,shading:THREE.FlatShading, vertexColors: THREE.VertexColors })
        mat = new THREE.LineBasicMaterial({color: 0xFFFFFF, lineWidth: 1})
        mat = new THREE.MeshLambertMaterial({color: 0xFFFFFF,shading:THREE.FlatShading, vertexColors: THREE.VertexColors})
        shine= 1500
        spec= 10000000000
        mat = new THREE.MeshPhongMaterial({color:  0xFFFFFF , shading: THREE.SmoothShading,  shininess: shine, specular: spec, metal: true, vertexColors: THREE.VertexColors}) 
        
        if @mesh?
          @scene.remove @mesh
          try
            @scene.remove @current.cageView
            @current=null
          
        @mesh = new THREE.Mesh(geom, mat)
        @mesh.castShadow =  @settings.get("shadows")
        @mesh.receiveShadow = @settings.get("selfShadows") and @settings.get("shadows")
        
        @mesh.name = "CSG_OBJ"
        
        @scene.add @mesh
        @controller.objects = [@mesh]
      catch error
        @scene.remove @mesh
        @model.csg = null
        console.log "Csg Generation error: #{error} "
        @app.vent.trigger("csgParseError", error)
      finally
        @app.vent.trigger("parseCsgDone", @)
        @_render()
      
    addObjs: () =>
      @cube = new THREE.Mesh(new THREE.CubeGeometry(50,50,50),new THREE.MeshBasicMaterial({color: 0x000000}))
      @scene.add(@cube)
      #set up material
      sphereMaterial =
      new THREE.MeshLambertMaterial
        color: 0xCC0000
      
      radius = 50
      segments = 16
      rings = 16

      sphere = new THREE.Mesh(
      
        new THREE.SphereGeometry(
          radius,
          segments,
          rings),
      
        sphereMaterial)
      sphere.name="Shinyyy"
      @scene.add(sphere)
      

  return GlThreeView

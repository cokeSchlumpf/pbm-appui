define ["jquery", "jquery", "jquery-ui"], ($, jQuery) ->

  constants =
    attributes:
      CLASSNAME:        "classname"
      JUSTIFYCONTENT:   "justifyContent"
      LAYOUT:           "layout"
      POSITION:         "position"
      REPLACEWITH:      "replaceWith"
      SIZE:             "size"
      WEIGHT:           "weight"
    
    attributevalues:
      position:
        TOP:     "top"
        LEFT:    "left"
        RIGHT:   "right"
        BOTTOM:  "bottom"
        CENTER:  "center"

    # object to change...
    LAY_BORDER:           "border"
    
    css:
      VERTICAL:         "pbm-applayout-vertical"
      HORIZONTAL:       "pbm-applayout-horizontal"
      ITEM:             "pbm-applayout-item"
      ITEM_FIXED:       (weight) -> "pbm-applayout-item-fixed-#{weight}"

  abstracts =
    layouts:
      simple: (directionCSS) ->
        transform: (container, attributes) ->
          justifyContent = $(container).attr(constants.attributes.JUSTIFYCONTENT)
          
          $(container).addClass(directionCSS).children().each((index, element) ->
            options.layouts.__helper.addSizing($(element), if justifycContent? then { size: "auto" } else { weight: 1 })
          )


  ###
  # configuration object
  ###
  options =
    common:
      prefix: "pbm-"
      cleanAttributes: Object.keys(constants.attributes)
    
    container:
      application:
        classname: "application"
        replaceWith: "div"
        
      panel:
        classname: "panel"
        replaceWith: "div"
        
    layouts:
      __helper:
        ###
        #
        ###
        addSizing: (element, standard) ->
          setSizeTo = (size) ->
            element.css((if isVertical then "height" else "width"), size + (if not isNaN(size) then "px" else ""))
            
          isVertical = element.parent().hasClass(constants.css.VERTICAL)

          if element.attr(constants.attributes.SIZE)?
            setSizeTo element.attr(constants.attributes.SIZE)
          else if standard.size?
            setSizeTo standard.size
          else
            classname = constants.css.ITEM_FIXED(option($(element).attr(constants.attributes.WEIGHT)).getOrElse(standard.weight))
            element.addClass(classname)
            
          element.addClass(constants.css.ITEM)        
            
      border:
        transform: (container, attributes) ->
          addSizing = (element, defaultWeight, isVertical) -> options.layouts.__helper.addSizing(element, { weight: defaultWeight })
            
          $(container).addClass(constants.css.VERTICAL)
      
          top = $("> panel[#{constants.attributes.POSITION}='#{constants.attributevalues.position.TOP}']", container)
          left = $("> :container[#{constants.attributes.POSITION}='#{constants.attributevalues.position.LEFT}']", container)
          right = $("> :container[#{constants.attributes.POSITION}='#{constants.attributevalues.position.RIGHT}']", container)
          center = $("> :container[#{constants.attributes.POSITION}='#{constants.attributevalues.position.CENTER}']", container)
          bottom = $("> :container[#{constants.attributes.POSITION}='#{constants.attributevalues.position.BOTTOM}']", container)
          
          middle = if (left? or center? or right?) then $("<panel></panel>").addClass(constants.css.HORIZONTAL) else undefined       
            
          if top.length > 0
            $(container).prepend(top)
            addSizing(top, 1, true)
            
          if middle?
            if top.length > 0 
              $(middle).insertAfter(top) 
            else
              $(container).prepend(middle)
              
            addSizing(middle, 4, true)
            
          if bottom.length > 0
            if middle?
              $(bottom).insertAfter(middle) 
            else if top.length > 0
              $(bottom).insertAfter(top)
            else 
              $(container).prepend(bottom)
  
            addSizing(bottom, 1, true)
            
          if left.length > 0
            $(middle).append(left)
            addSizing(left, 1, false)
  
          if center.length > 0
            $(middle).append(center)
            addSizing(center, 4, false)
            
          if right.length > 0
            $(middle).append(right)
            addSizing(right, 1, false) 
            
      vertical: abstracts.layouts.simple(constants.css.VERTICAL)
      horizontal: abstracts.layouts.simple(constants.css.HORIZONTAL)
    
  ###
  # Extend jQuery with a container selector to select configured containers.
  ###
  $.expr[':'].container = (element, i, m) ->    
    options.container.hasOwnProperty element.tagName.toLowerCase()
    
  option = (value) ->
    get: value
    getOrElse: (defaultValue) ->
      if value? then value else defaultValue

  cleanAttributes = (  
    result = [ ]
    result.push(constants.attributes[key]) for key in Object.keys(constants.attributes)
    result)

  ###
  # Replaces the application xml container element with a valid HTML 5 tag.
  ###
  _replaceContainer = (element) ->
    classname = option($(element).attr(constants.attributes.CLASSNAME)).getOrElse(options.common.prefix + options.container[element.tagName.toLowerCase()].classname)
    replaceWithTag = option($(element).attr(constants.attributes.REPLACEWITH)).getOrElse(options.container[element.tagName.toLowerCase()].replaceWith)
    
    newElement = $("""<#{replaceWithTag} />""")

    # Append children to new element.
    if $(element).children().length > 0
      $(element).children().appendTo(newElement)
    else
      $(newElement).html($(element).html())
      
    # Add all attributes to new element except for application layout specific attributes ...
    $(element.attributes).each((index, element) -> if (element.name not in cleanAttributes) then $(newElement).attr(element.name, element.value))
    $(newElement).addClass(classname)
    
    # Replace old element with valid/ new HTML5 element.
    $(element).replaceWith(newElement)   
    
    newElement 

  ###
  # Parses an element for UI Tags and replaces them with valid HTML5.
  ###
  parseUiXml = (element) -> 
    $("> :container", element).each((index, container) ->
      newContainer  = _replaceContainer(container)
      
      attributes = {}
      attributes[attr.name] = attr.value for attr in container.attributes
        
      layoutname = attributes[constants.attributes.LAYOUT]
      layout = options.layouts[layoutname]

      if layout? then layout.transform(newContainer, attributes)
      
      parseUiXml newContainer
    )

  ###
  # Define jQuery UI Plugin
  ###
  $.widget "pbm.application",

    # defualt options
    options: {}
    
    # create function
    _create: ->
      parseUiXml this.element
      
    # destroy function called on destruction of component
    destroy: ->
      $.Widget.prototype.destroy.call this
      
    # handle option configuration
    _setOption: (key, value) ->
      switch key
        when "someValue"
          # this.options.someValue = doSomethingWith value
        else
          this.options[key] = value
      
      this._super "_setOption", key, value
      
    # sample method a
    methodA: (event) ->
      this._trigger "dataChanged", event, { key: "someValue" }
      
    # sample method b
    methodB: (event) ->
      console.log "Method B triggered."
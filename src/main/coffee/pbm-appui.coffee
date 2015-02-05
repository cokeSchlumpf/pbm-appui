define ["jquery", "jquery", "jquery-ui"], ($, jQuery) ->

  ###
  # Extend jQuery with a container selector to select configured containers.
  ###
  $.expr[':'].container = (element, i, m) ->    
    element.tagName.toLowerCase() in AppUI.getContainers()
    
  ###
  # Option wrapper for easier default value handling.
  ###      
  Option = 
    From: (value) ->
      isDefined: value?
      get: value
      getOrElse: (defaultValue) ->
        if value? then value else defaultValue
      
    None:
      isDefined: false
      getOrElse: (defaultValue) -> 
        defaultValue

  ###
  #
  # The Application UI object.
  #
  ### 
  AppUI = 

    ###
    # Internal constants used throughout the code.
    ###
    _constants:
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
          TOP:            "top"
          LEFT:           "left"
          RIGHT:          "right"
          BOTTOM:         "bottom"
          CENTER:          "center"
      
      css:
        VERTICAL:         "pbm-applayout-vertical"
        HORIZONTAL:       "pbm-applayout-horizontal"
        ITEM:             "pbm-applayout-item"
        ITEM_FIXED:       (weight) -> "pbm-applayout-item-fixed-#{weight}"

    ###
    # Returns a list of all available attributes.
    ###
    _cleanAttributes: () ->  
      result = [ ]
      result.push(AppUI._constants.attributes[key]) for key in Object.keys(AppUI._constants.attributes)
      result
    
    ###
    # Helper function to configure the size of a layout item.
    ###
    _addSizing: (element, standard) ->
      setSizeTo = (size) ->
        element.css((if isVertical then "height" else "width"), size + (if not isNaN(size) then "px" else ""))
        
      isVertical = element.parent().hasClass(this._constants.css.VERTICAL)
  
      if element.attr(this._constants.attributes.SIZE)?
        setSizeTo element.attr(this._constants.attributes.SIZE)
      else if standard.size?
        setSizeTo standard.size
      else
        classname = this._constants.css.ITEM_FIXED(Option.From($(element).attr(this._constants.attributes.WEIGHT)).getOrElse(standard.weight))
        element.addClass(classname)
        
      element.addClass(this._constants.css.ITEM)  

    ###
    # Contains the Application Layout configuration.
    ###
    options:

      ## Common configuration.
      common:
        prefix: "pbm-"

      ## Defined container elements.
      container:
        _example:
          classname:    "example"     # The CSS class name
          replaceWith:  "div"         # The HTML Tag which will be used to replace the container element
          size:         Option.None   # Optional default size for the container     
      
      ## Defined layout types. 
      layouts:   
        _example:
          ###
          # Transforms the containers children to the configured layout type.
          #
          # @param container  The container which has the configured layout type.
          # @param attributes The attributes of the container.
          ###
          transform: (container, attributes) ->
            console.log("Add layout initialization code here.")
        
        ###
        # Simple Layout constructor.
        #
        # @param directionCSS The CSS class to spcify the orientation of the layout. 
        ###
        _simple: (directionCSS) ->
          transform: (container, attributes) ->
            justifyContent = $(container).attr(AppUI._constants.attributes.JUSTIFYCONTENT)
            
            $(container).addClass(directionCSS).children().each((index, element) ->
              AppUI._addSizing($(element), if justifycContent? then { size: "auto" } else { weight: 1 })
            )
            
            $(container).addClass("pbm-applayout-justify-#{justifyContent}") if justifyContent?
      
    ###
    # Replaces the application xml container element with a valid HTML 5 tag.
    ###
    _replaceContainer: (element) ->
      self = this
      options = this.options
      constants = this._constants
      
      defaultClassname = options.common.prefix + options.container[element.tagName.toLowerCase()].classname
      defaultReplaceWith = options.container[element.tagName.toLowerCase()].replaceWith
      
      classname = Option.From($(element).attr(constants.attributes.CLASSNAME)).getOrElse(defaultClassname)
      replaceWith = Option.From($(element).attr(constants.attributes.REPLACEWITH)).getOrElse(defaultReplaceWith)
      
      newElement = $("""<#{replaceWith} />""")
  
      # Append children to new element.
      if $(element).children().length > 0
        $(element).children().appendTo(newElement)
      else
        $(newElement).html($(element).html())
        
      # Add all attributes to new element except for application layout specific attributes ...
      $(element.attributes).each((index, element) -> if (element.name not in self._cleanAttributes) then $(newElement).attr(element.name, element.value))
      $(newElement).addClass(classname)
      
      # Replace old element with valid/ new HTML5 element.
      $(element).replaceWith(newElement)
      
      newElement 

    ###
    # Parses an element for UI Tags and replaces them with valid HTML5.
    #
    # @param element  The DOM element which contains the application XML layout.
    ###
    render: (element) -> 
      self = this
      
      $("> :container", element).each((index, container) ->
        newContainer  = self._replaceContainer(container)
        
        attributes = {}
        attributes[attr.name] = attr.value for attr in container.attributes
          
        layoutname = attributes[self._constants.attributes.LAYOUT]
        layout = self.options.layouts[layoutname]
  
        if layout? then layout.transform(newContainer, attributes)
        
        self.render(newContainer)
      )
      
    ###
    # Creates a new layout and adds it to the App UI configuration.
    #
    # @param name
    # @param configuration
    ###
    createLayout: (name, configuration) ->
      this.options.layouts[name] = configuration
      
    ###
    # Creates a new layout container and adds it to the App UI configuration.
    #
    # @param name
    # @param configuration
    ###
    createContainer: (name, configuration) ->
      this.options.container[name] = configuration
    
    ###
    # Returns a list of configured containers.
    ###  
    getContainers: () ->
      Object.keys(this.options.container)
     
  ###
  #
  # Add default layouts.
  #
  ### 
  AppUI.createLayout("vertical", AppUI.options.layouts._simple(AppUI._constants.css.VERTICAL))
  
  AppUI.createLayout("horizontal", AppUI.options.layouts._simple(AppUI._constants.css.HORIZONTAL))
  
  AppUI.createLayout("border", {
    transform: (container, attributes) ->
      $(container).addClass(AppUI._constants.css.VERTICAL)
  
      top = $("> panel[#{AppUI._constants.attributes.POSITION}='#{AppUI._constants.attributevalues.position.TOP}']", container)
      left = $("> :container[#{AppUI._constants.attributes.POSITION}='#{AppUI._constants.attributevalues.position.LEFT}']", container)
      right = $("> :container[#{AppUI._constants.attributes.POSITION}='#{AppUI._constants.attributevalues.position.RIGHT}']", container)
      center = $("> :container[#{AppUI._constants.attributes.POSITION}='#{AppUI._constants.attributevalues.position.CENTER}']", container)
      bottom = $("> :container[#{AppUI._constants.attributes.POSITION}='#{AppUI._constants.attributevalues.position.BOTTOM}']", container)
      
      middle = if (left.length > 0 or center.length > 0 or right.length > 0) then $("<panel></panel>").addClass(AppUI._constants.css.HORIZONTAL) else undefined       
        
      if top.length > 0
        $(container).prepend(top)
        AppUI._addSizing(top, { weight: 1 })
        
      if middle?
        if top.length > 0 
          $(middle).insertAfter(top) 
        else
          $(container).prepend(middle)
          
        AppUI._addSizing(middle, { weight: 4 })
        
      if bottom.length > 0
        if middle?
          $(bottom).insertAfter(middle) 
        else if top.length > 0
          $(bottom).insertAfter(top)
        else 
          $(container).prepend(bottom)

        AppUI._addSizing(bottom, { weight: 1 })
        
      if left.length > 0
        $(middle).append(left)
        AppUI._addSizing(left, { weight: 1 })

      if center.length > 0
        $(middle).append(center)
        AppUI._addSizing(center, { weight: 4 })
        
      if right.length > 0
        $(middle).append(right)
        AppUI._addSizing(right, { weight: 1 }) 
  })
  
  
  ###
  #
  # Add default containers.
  #
  ### 
  AppUI.createContainer("application", {
    classname:    "application"
    replaceWith:  "div"
  })
   
  AppUI.createContainer("panel", {
    classname:    "panel"
    replaceWith:  "div"
  })
  
  AppUI.createContainer("titlebar", {        
    classname:    "titlebar"
    replaceWith:  "div"
    size:         Option.From(40)
  })
    
  ###
  # Define jQuery UI Plugin
  ###
  $.widget "pbm.application", 
  
    options: { }
  
    # create function
    _create: ->
      AppUI.render(this.element)
      
    # destroy function called on destruction of component
    destroy: ->
      $.Widget.prototype.destroy.call this
      
    # handle option configuration
    _setOption: (key, value) ->
      switch key
        when "someValue"
          # this.options.FromValue = doSomethingWith value
        else
          this.options[key] = value
      
      this._super "_setOption", key, value
      
    # sample method a
    methodA: (event) ->
      this._trigger "dataChanged", event, { key: "someValue" }
      
    # sample method b
    methodB: (event) ->
      console.log "Method B triggered."
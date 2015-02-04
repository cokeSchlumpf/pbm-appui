define ["jquery", "jquery", "jquery-ui"], ($, jQuery) ->

  constants =
    TAG_LAYOUT:           "layout"
    TAG_REPLACEWITH:      "replaceWith"
    TAG_CLASSNAME:        "classname"
    TAG_POSITION:         "position"
    TAG_WEIGHT:           "weight"
    TAG_SIZE:             "size"
    
    TAG_POSITION_TOP:     "top"
    TAG_POSITION_LEFT:    "left"
    TAG_POSITION_RIGHT:   "right"
    TAG_POSITION_BOTTOM:  "bottom"
    TAG_POSITION_CENTER:  "center"

    LAY_BORDER:           "border"
    
    CSS_VERTICAL:         "pbm-applayout-vertical"
    CSS_HORIZONTAL:       "pbm-applayout-horizontal"
    CSS_ITEM:             (weight) -> "pbm-applayout-item-fixed-#{weight}"

  ###
  # configuration object
  ###
  configuration =
    common:
      prefix: "pbm-"
      cleanAttributes: [ constants.TAG_LAYOUT, constants.TAG_REPLACEWITH, constants.TAG_CLASSNAME, constants.TAG_POSITION, constants.TAG_WEIGHT, constants.TAG_SIZE ]
    
    container:
      application:
        classname: "application"
        replaceWith: "div"
        
      panel:
        classname: "panel"
        replaceWith: "div"
    
  ###
  # Extend jQuery with a container selector to select configured containers.
  ###
  $.expr[':'].container = (element, i, m) ->    
    configuration.container.hasOwnProperty element.tagName.toLowerCase()
    
  option = (value) ->
    get: value
    getOrElse: (defaultValue) ->
      if value? then value else defaultValue

  ###
  # Replaces the application xml container element with a valid HTML 5 tag.
  ###
  _replaceContainer = (element) ->
    classname = option($(element).attr(constants.TAG_CLASSNAME)).getOrElse(configuration.common.prefix + configuration.container[element.tagName.toLowerCase()].classname)
    replaceWithTag = option($(element).attr(constants.TAG_REPLACEWITH)).getOrElse(configuration.container[element.tagName.toLowerCase()].replaceWith)
    
    newElement = $("""<#{replaceWithTag} />""")

    # Append children to new element.
    if $(element).children().length > 0
      $(element).children().appendTo(newElement)
    else
      $(newElement).html($(element).html())
      
    # Add all attributes to new element.
    $(element.attributes).each((index, element) -> if (element.name not in configuration.common.cleanAttributes) then $(newElement).attr(element.name, element.value))
    $(newElement).addClass(classname)
    
    # Replace old element with valid/ new HTML5 element.
    $(element).replaceWith(newElement)   
    
    newElement 
    
  ###
  # Creates the layout within a container.
  #
  # @param container The container which should be analyzed and transformed.
  # @param layoutname The name of the layout.
  ###
  _createContainerLayout = (container, layoutname) ->
    addSizing = (element, defaultWeight, isVertical) ->
      if element.attr(constants.TAG_SIZE)?
        element.css((if isVertical then "height" else "width"), "#{element.attr(constants.TAG_SIZE)}px")
      else
        classname = constants.CSS_ITEM(option($(element).attr(constants.TAG_WEIGHT)).getOrElse(defaultWeight))
        element.addClass(classname)
    
    switch layoutname    
      when constants.LAY_BORDER 
        $(container).addClass(constants.CSS_VERTICAL)
        
        top = $("> panel[#{constants.TAG_POSITION}='#{constants.TAG_POSITION_TOP}']", container)
        left = $("> :container[#{constants.TAG_POSITION}='#{constants.TAG_POSITION_LEFT}']", container)
        right = $("> :container[#{constants.TAG_POSITION}='#{constants.TAG_POSITION_RIGHT}']", container)
        center = $("> :container[#{constants.TAG_POSITION}='#{constants.TAG_POSITION_CENTER}']", container)
        bottom = $("> :container[#{constants.TAG_POSITION}='#{constants.TAG_POSITION_BOTTOM}']", container)
        
        middle = if (left? or center? or right?) then $("<panel></panel>").addClass(constants.CSS_HORIZONTAL) else undefined       
          
        if top.length > 0
          $(container).prepend(top)
          addSizing(top, 1, true)
          top.attr("bla", "HUHU")
          
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
      else
        # use default HTML Layout ... 
        # console.log("Unknwon layout type `#{layoutname}`.")

  ###
  # Parses an element for UI Tags and replaces them with valid HTML5.
  ###
  parseUiXml = (element) -> 
    $("> :container", element).each((index, container) ->
      newContainer  = _replaceContainer(container)
      _createContainerLayout(newContainer, $(container).attr(constants.TAG_LAYOUT))
      
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
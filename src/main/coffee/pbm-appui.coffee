define ["jquery", "jquery-ui"], ($) ->

  $.widget "pbm.appui",

    # defualt options
    options: {}
    
    # create function
    _create: ->
      this.element.html "Hallo zusammen!"
      
    destroy: ->
      $.Widget.prototype.destroy.call this
      
    methodA: (event) ->
      this._trigger "dataChanged", event, { key: "someValue" }
      
    methodB: (event) ->
      console.log "Method B triggered."
      
    _setOption: (key, value) ->
      switch key
        when "someValue"
          # this.options.someValue = doSomethingWith value
        else
          this.options[key] = value
      
      this._super "_setOption", key, value
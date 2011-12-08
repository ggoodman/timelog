###
View

###


window.lumbar = 
  version: "0.0.1"
  start: -> lumbar.root.render()

class lumbar.View
  fragment: "<div>"
  template: ->
    
  attach: (mountPoint, childView) -> @children[mountPoint] = childView
    
  getViewModel: -> _.extend {}, @model?.viewModel()
    
  render: ->
    @el.html CoffeeKup.render @template, @getViewModel()
    
    for mountPoint, childView of @children
      $(mountPoint, @el).clear().append $(childView.render().el).contents()
    
    @trigger "rendered", @
  
  initialize: ->
    
  constructor: ->
    @children? or @children = {}
    @el = $(@fragment)
    @initialize(arguments...)

lumbar.root = new class extends lumbar.View
  fragment: "body"
  template: ->
    div "#wrapper", ->
      div "#pages", ->

class lumbar.Model extends Backbone.Model
  viewModel: => _.extend {}, if _.isFunction(@expose) then @expose() else @toJSON()

class lumbar.Collection extends Backbone.Collection

class lumbar.View extends Backbone.View
  template: ->
  render: =>
    options = _.extend {}, @, @model?.viewModel()
    $(@el).html CoffeeKup.render @template, options
    @trigger "rendered"
    @

class lumbar.Page extends lumbar.View
  tagName: "div"
  className: "page"
  attach: (name, view) ->
    @children[name] = view
    @children[name].render()

    $("##{name}").html(@children[name].el)

  initialize: (options) ->
    $(@render().el).hide().appendTo("#pages")

    @children = {}
    @attach name, view for name, view of options


class lumbar.Router extends Backbone.Router
  initialize: ->
    @pages = {}
    @lastPageName = null
  
  registerPage: (route, name, callback) ->
    self = @
    @route route, name, ->
      console.log "Route #{name}:", arguments...
      unless self.pages[name]
        self.pages[name] = _.defaults callback(),
          prepare: ->
          show: ->
          hide: ->
      
      self.pages[name].prepare(arguments...)

      unless self.lastPageName == name
        self.pages[self.lastPageName].hide() if self.lastPageName
        self.pages[name].show()
      
      self.lastPageName = name

  start: ->
    Backbone.history.start pushState: false

lumbar.router = new lumbar.Router
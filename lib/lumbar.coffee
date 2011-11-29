window.lumbar = 
  version: "0.0.1"

class lumbar.Model extends Backbone.Model
  viewModel: => _.extend {}, if _.isFunction(@expose) then @expose() else @toJSON()

class lumbar.Collection extends Backbone.Collection

class lumbar.View extends Backbone.View
  template: ->
  render: =>
    options = _.extend {}, @, @model?.viewModel()
    console.log "lumbar.View.render", @
    $(@el).html CoffeeKup.render @template, options
    @trigger "rendered", @
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

    console.log "@el", @el


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
###
View

###


window.lumbar = 
  version: "0.0.1"
  start: -> lumbar.root.render()

class lumbar.View
  @attachDefaults:
    mountPoint: "@"
    mountMethod: "html"
    type: "one"

  @attach: (name, options = {}) ->
    @attachedViews ?= {}
    @attachedViews[name] = _.defaults options, @attachDefaults

  mountMethod: "html" # Replace contents with rendered template
  renderEvents: "all" # Re-render on 'all' events
  template: ->
  initialize: ->

  setMountPoint: (@mountPoint) ->
  setMountMethod: (@mountMethod) ->
  
  render: =>
    @$ = $(CoffeeKup.render @template, @getViewModel())
    if @mountPoint
      $(@mountPoint)[@mountMethod](@$)
      @emit "mounted"
    @emit "rendered"
    @renderAttachedViews()
    @

  renderAttachedView: (name, options) ->
    # Check to see if the viewModel needs to be lazy-loaded
    if options.createViewModel and not options.viewModel
      throw new Error("createViewModel must be a function") unless _.isFunction(options.createViewModel)
      options.viewModel = options.createViewModel.call(@)

    throw new Error("Missing or invalid viewModel") unless options.viewModel instanceof lumbar.View

    childView.setMountPoint if options.mountPoint is "@" then @$ else @$.find(options.mountPoint)
    childView.setMountMethod options.mountMethod
    childView.render()

  renderAttachedViewList: (name, options) ->
    if options.createIterator and not options.iterator
      throw new Error("createIterator must be a function") unless _.isFunction(options.createIterator)
      options.iterator = options.createIterator.call(@)

    throw new Error("Missing or invalid iterator") unless _.isFunction(options.iterator)

    self = @
    options.iterator.call @, name, options, (viewModel) ->
      self.renderAttachedView name, _.extend {}, options,
        type: "one"
        viewModel: viewModel

  renderAttachedViews: ->
    for name, options of @attachedViews
      if options.type is "one" then @renderAttachedView(name, options)
      else if options.type is "many" then @renderAttachedViewList(name, options)
      else throw new Error("Invalid attachment type: #{options.type}")
    @
        

  constructor: (options = {}) ->
    @[key] = value for key, value of options when not @[key]

    # Transfer over things set-up through constructor-level methods
    @attachDefaults = @constructor.attachDefaults
    @attach = @constructor.attach
    @attachedViews = @constructor.attachedViews

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
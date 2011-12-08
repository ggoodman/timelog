lumbar.router.registerPage /^(\d\d\d\d-\d\d-\d\d)?$/, "date", ->
  
  class Statistics extends lumbar.View
    tagName: "div"
    className: "statistics"
    template: ->
      stats = timelog.day.reduce(((memo, block) ->
        type = if block.id then "recorded" else "unrecorded"
        memo[type] += block.get("end").diff(block.get("start"), "hours", true)
        memo
      ), {recorded: 0, unrecorded: 0})
      
      strong "Recorded: "
      span sprintf("%1.1f", stats.recorded)
      br ""
      strong "Unrecorded: "
      span sprintf("%1.1f", stats.unrecorded)
    
    initialize: ->
      @collection.bind "all", _.throttle(@render, 500)
      
  class Toolbar extends lumbar.View
    tagName: "div"
    template: ->
      yesterday = @date.clone().subtract("days", 1)
      tomorrow = @date.clone().add("days", 1)
      a ".prev", href: "#" + yesterday.format("YYYY-MM-DD"), ->
        "<"
      h3 ".date", ->
        time @date.format("ddd DD MMM YYYY")
      if tomorrow.diff(moment().clearTime(), "days") <= 0
        a ".next", href: "#" + tomorrow.format("YYYY-MM-DD"), ->
          ">"
      else
        span ".next", ->
          ">"
      div ".stats", ->

    initialize: ->
      @model.bind "change:date", @render
      
      @bind "rendered", =>
        @$(".stats").append (new Statistics(collection: timelog.day)).render().el
      
  class BlockView extends lumbar.View
    tagName: "div"
    className: "block"
    template: ->
      cls = if @id then "recorded" else "unrecorded"
      
      div ".#{cls}", ->
        a href: @url(), ->
          div ".range", ->
            time @start.format("h:mma")
            br ""
            time @end.format("h:mma")
          div ".duration", sprintf "%1.1fh", @end.diff(@start, "hours", true)
          h3 ".title", @title or "Unrecorded time"
          if @id then p ".description", @description
      

  class BlocksView extends lumbar.View
    tagName: "div"
    className: "blocks"
    initialize: ->
      @blockViews = {}
      @collection.bind "all", @render
    render: =>
      self = @
      $list = $(@el).empty()
      @collection.each (block) ->
        $list.append (new BlockView(model: block)).render().el
     
  
  class DateView extends lumbar.Page
    tagName: "div"
    template: ->
      div "#toolbar", ->
      div "#blocks", ->

  
  view = new DateView
    toolbar: new Toolbar(model: timelog.state)
    #tracker: new Tracker(model: new TailEnd)
    blocks: new BlocksView(collection: timelog.day)

  #Return the public page interface
  prepare: (date) ->
    date = if date? then moment(date, "YYYY-MM-DD") else moment().clearTime()
    timelog.state.set(date: date)
  show: -> $(view.el).fadeIn()
  hide: -> $(view.el).fadeOut()
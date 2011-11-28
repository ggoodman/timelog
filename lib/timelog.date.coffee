lumbar.router.registerPage /^(\d\d\d\d-\d\d-\d\d)?$/, "date", ->
  class Toolbar extends lumbar.View
    tagName: "div"
    template: ->
      yesterday = @date.clone().subtract("days", 1)
      tomorrow = @date.clone().add("days", 1)
      a ".btn.prev.pull-left", href: "#" + yesterday.format("YYYY-MM-DD"), ->
        yesterday.format("DD MMM")
      a ".btn.next.pull-right", href: "#" + tomorrow.format("YYYY-MM-DD"), ->
        tomorrow.format("DD MMM")
      h3 ->
        time @date.format("ddd DD MMM YYYY")

    initialize: ->
      @model.bind "change:date", @render


  class BlockView extends lumbar.View
    tagName: "div"
    className: "block"
    template: ->
      div {class: if @title then "allocated" else "unallocated"}, ->
        p ".pull-right", @start.format("HH:mm") + "-" + @end.format("HH:mm")
        h3 @title or "Unallocated"
        p @description
        div ".operations", ->
          a ".btn.small", href: @url(), -> "Edit"

  class BlocksView extends lumbar.View
    tagName: "div"
    className: "blocks"
    initialize: ->
      @blockViews = {}
      @collection.bind "all", @render
    render: =>
      self = @
      $list = $(@el).empty()
      _.each @collection.models.reverse(), (block) ->
        unless self.blockViews[block.cid]
          self.blockViews[block.cid] = new BlockView(model: block)
        $list.append self.blockViews[block.cid].render().el
  
  class TailEnd extends timelog.Block
    initialize: ->

      self = @
      self.set
        end: timelog.state.get("clock").clone()
        start: timelog.blocks.last()?.get("end") or moment().clearTime()
      timelog.state.bind "change:clock", (state) ->
        self.set end: timelog.state.get("clock").clone()
      timelog.day.bind "all", _.throttle ( (day) ->
        self.set start: timelog.blocks.last()?.get("end") or moment().clearTime()
      ), 100

  class Tracker extends lumbar.View
    tagName: "div"
    #events:
    #  "click .checkin": "checkIn"
    template: ->
      a href: @url(), ->
        h1 @start.from(@end)
        p "was the last time you checked in."
        p "Click here to check in."

    initialize: ->
      @model.bind "change", @render
  
  class DateView extends lumbar.Page
    tagName: "div"
    template: ->
      div "#tracker", ->
      div "#toolbar", ->
      div "#blocks", ->

  
  view = new DateView
    toolbar: new Toolbar(model: timelog.state)
    tracker: new Tracker(model: new TailEnd)
    blocks: new BlocksView(collection: timelog.day)

  #Return the public page interface
  prepare: (date) ->
    timelog.state.set(date: moment(date, "YYYY-MM-DD")) if date?
  show: -> $(view.el).fadeIn()
  hide: -> $(view.el).fadeOut()
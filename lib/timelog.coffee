window.timelog =
  version: "0.0.1"
  interval: 6 * 60
  start: ->
    @entries = new timelog.Entries
    @state = new timelog.State
    @day = new timelog.Day
    
    @entries.fetch()
    
    lumbar.router.start()

moment.fn.equals = (date) ->
  @diff(date) <= timelog.interval

moment.fn.isSameDateAs = (date) ->
  @format("YYYY-MM-DD") == date.format("YYYY-MM-DD")

moment.fn.toString = (format = "YYYY-MM-DD HH:mm") ->
  @format(format)
moment.fn.toJSON = ->
  @toString()
moment.fn.nearestMinutes = (n) ->
  @minutes Math.round(@minutes() / 6) * 6

moment.fn.clearTime = -> @hours(0).minutes(0).seconds(0)

class timelog.Entry extends lumbar.Model
  defaults: ->
    title: null
    description: null
    start: moment().clearTime()
    end: moment()
  generateId: -> @get("start").format("YYYY-MM-DD@HH:mm")
  expose: => _.extend {}, @toJSON(),
    url: =>
      if @isNew() then "#" + @get("start").format("YYYY-MM-DD") + "?start=" + @get("start").format("HH:mm") + "&end=" + @get("end").format("HH:mm")
      else "##{@id}"

class timelog.Entries extends lumbar.Collection
  model: timelog.Entry
  localStorage: new Store("timelog.blocks")
  comparator: (entry) -> -entry.get("start").valueOf()
  parse: (json) ->
    _.map json, (record) ->
      id: record.id
      start: moment(record.start, "YYYY-MM-DD HH:mm")
      end: moment(record.end, "YYYY-MM-DD HH:mm")
      title: record.title
      description: record.description


class timelog.State extends lumbar.Model
  tick: => @set clock: moment()
  initialize: ->
    @set
      date: moment().clearTime()
      clock: moment()

    #@interval = setInterval(@tick, 5000)

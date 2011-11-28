window.timelog =
  version: "0.0.1"
  interval: 6 * 60

moment.fn.equals = (date) ->
  @diff(date) <= timelog.interval

moment.fn.isSameDateAs = (date) ->
  @format("YYYY-MM-DD") == date.format("YYYY-MM-DD")

moment.fn.toString = (format = "YYYY-MM-DD HH:mm") ->
  @format(format)
moment.fn.toJSON = ->
  console.log "Formatting", @, @toString()
  @toString()
  

moment.fn.clearTime = -> @hours(0).minutes(0).seconds(0)

class timelog.Block extends lumbar.Model
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

class timelog.Blocks extends lumbar.Collection
  model: timelog.Block
  localStorage: new Store("timelog.blocks")
  comparator: (block) -> block.get("start").valueOf()
  parse: (json) ->
    console.log "json", json
    _.map json, (record) ->
      id: record.id
      start: moment(record.start, "YYYY-MM-DD HH:mm")
      end: moment(record.end, "YYYY-MM-DD HH:mm")
      title: record.title
      description: record.description

timelog.blocks = new timelog.Blocks

class timelog.State extends lumbar.Model
  tick: => @set clock: moment()
  initialize: ->
    @set
      date: moment().clearTime()
      clock: moment()
      last: moment().clearTime()
    
    #@interval = setInterval(@tick, 5000)

    self = @
    timelog.blocks.bind "all", =>
      today = moment().clearTime()
      last = timelog.blocks.last()?.get("end") or today
      @set last: if today.valueOf() > last.valueOf() then today else last

timelog.state = new timelog.State

class timelog.Day extends timelog.Blocks
  initialize: ->
    self = @
    timelog.state.bind "change:date", ->
      self.resetFromDate(timelog.state.get("date"))
    timelog.blocks.bind "all", _.throttle (
      -> self.resetFromDate(timelog.state.get("date"))
    ), 100    
  
  resetFromDate: (date) ->
    start = moment(date).clearTime()
    end = moment(start.clone().add("days", 1).valueOf() - 1)
    console.log "timelog.Day.resetFromDate", date, date?.toString()
    blocks = timelog.blocks.filter (block) -> block.get("start").isSameDateAs(start)
    last = start.clone()
    day = []
    _.each blocks, (block) ->
      unless block.get("start").equals(last)
        day.push new timelog.Block
          start: last.clone()
          end: block.get("start").clone()
      day.push block
      last = block.get("end").clone()
    if date.diff(moment().clearTime(), "days") < 0
      day.push new timelog.Block
        start: last.clone()
        end: end.clone()
    @reset day
    
timelog.day = new timelog.Day



###
console.log "DATA", data

_.each window.data, (record) ->
  timelog.blocks.create
    start: moment(record.start)
    end: moment(record.end)
    title: record.title
    description: record.description
###
timelog.blocks.fetch()

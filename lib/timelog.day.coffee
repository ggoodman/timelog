((timelog) ->
 
  class timelog.Block extends lumbar.Model
    expose: => _.extend {}, @toJSON(),
      url: => "#" + @get("start").format("YYYY-MM-DD") + "@#{@cid}"
      cid: @cid
      
    getEarliestStart: ->
      if @prev and not @prev.id then @prev.get("start")
      else @get("start")

    getLatestEnd: ->
      if @next and not @next.id then @next.get("end")
      else @get("end")

  class timelog.Day extends lumbar.Collection
    model: timelog.Block
    comparator: (block) -> -block.get("start").valueOf()
    
    initialize: ->
      # Handle changes to events collection
      #timelog.entries.bind "add", @onAddEvent
      #timelog.entries.bind "remove", @onRemoveEvent
      #timelog.entries.bind "reset", @onResetEvents
      timelog.entries.bind "all", @onResetEvents
  
      # Handle changes to the viewing date
      timelog.state.bind "change:date", @onDateChange
  
      # Handle changes to the clock
      timelog.state.bind "change:clock", @onClockChange
  
      # Initialize by triggering date/clock handlers
      @onDateChange()
  
    onAddEvent: (event) => @insertEvent(event)
    onRemoveEvent: (event) => @removeEvent(event)
    onResetEvents: => @onDateChange()
  
    # Handle changes to the application's date
    onDateChange: =>
      clock = timelog.state.get("clock")
      date = timelog.state.get("date")
  
      wholeDay =
        start: date.clone().clearTime()
        end: moment(date.clone().clearTime().add("days", 1).valueOf() - 1)
  
      if date.isSameDateAs(clock) then wholeDay.end = moment()
  
      # Reset the collection with the initial, whole-day event
      @reset [wholeDay]
  
      self = @
      timelog.entries.each (event) -> self.insertEvent(event) if event.get("start").isSameDateAs(date)
  
    # Handle changes to the application's clock
    onClockChange: (state) =>
      clock = state.get("clock")
      date = state.get("date")
  
      if date.isSameDateAs(clock)
        last = @last()
  
        if last.get("event") then @add(start: last.get("end").clone(), end: clock.clone())
        else last.set(end: clock.clone())
  
    # Insert an event into the day and adjust containing block
    insertEvent: (event) ->
      from = event.get("start").valueOf()
      to = event.get("end").valueOf()
  
      self = @
      self.each (block) ->
        start = block.get("start").valueOf()
        end = block.get("end").valueOf()
  
        # Start of event is within the block's interval
        if from > start and from < end
          throw new Error("Overlap detected") if to > end
  
          # Create a block corresponding to the event
          newEventBlock = new timelog.Block event.toJSON()
  
          self.add newEventBlock
          
          before = from - start
          after = end - to
  
          if before and after
            #Adjust existing block
            block.set(end: moment(from)) # Adjust end-time
  
            # Add block for time after event to be added
            newEmptyBlock = new timelog.Block
              start: moment(to)
              end: moment(end)
  
            self.add newEmptyBlock
  
            #Adjust next/prev links
            newEmptyBlock.next = block.next
            newEmptyBlock.prev = newEventBlock
  
            newEventBlock.next = newEmptyBlock
            newEventBlock.prev = block.prev
  
            block.next = newEventBlock
  
          else if before
            block.set(end: moment(from))
  
            # Adjust next/prev links
            newEventBlock.next = block.next
            newEventBlock.prev = block
  
            block.next = newEventBlock
          else if after
            block.set(start: moment(to))
  
            # Adjust next/prev links
            newEventBlock.next = block
            newEventBlock.prev = block.prev
  
            block.prev = newEventBlock
          else
            self.remove(block)
  
            # Adjust next/prev links
            newEventBlock.next = block.next
            newEventBlock.prev = block.prev
  
    # Remove an event and adjust surrounding event(s)
    removeEvent: (event) ->
      from = event.get("start").valueOf()
      to = event.get("end").valueOf()
  
      if block = @get(event.id)
        if block.before and block.after
          if block.before.id and block.after.id
            # Block is surrounded by events, replace with empty time
            @add(start: moment(from), end: moment(to))
          else if block.before.id
            # Block has empty space after
            block.after.set(start: moment(from))
          else
            block.before.set(end: moment(to))
        else if block.before
          # Block was the last block in the day
          block.before.set(end: moment(to))
        else if block.after
          # Block was the first block in the day
          block.after.set(start: moment(from))
        else
          # Block was the only block in the dya
          @add(start: moment(from), end: moment(to))
  
        @remove(block)

)(window.timelog)
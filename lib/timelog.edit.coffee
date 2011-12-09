lumbar.router.registerPage /^(\d\d\d\d-\d\d-\d\d)(?:@(c\d+))$/, "edit", ->
  class Form extends lumbar.Page
    events:
      "click .cancel": "cancel"
      "click .save": "save"
    tagName: "div"
    template: ->      
      form ".form-stacked", ->
        fieldset ->
          legend "Clock your time"
          div ".clearfix", ->
            label "Title"
            div ".input", ->
              input ".xlarge.title", tabindex: 1, name: "title", autocomplete: "off", placeholder: "Path/of/activity", value: @title
              span ".help-block", "The path of your activity helps structure your time."
          div ".clearfix", ->
            label "Description"
            div ".input", ->
              textarea ".xlarge", tabindex: 2, name: "description", placeholder: "Describe how you spent your time...", -> @description
          div ".clearfix", ->
            div ".input", div ".inline-inputs", ->
              select ".mini", tabindex: 3, name: "start", ->
              span "to"
              select ".mini", tabindex: 4, name: "end", ->
          div ".actions", ->
            a ".btn.primary.save", href: "##{@start.format('YYYY-MM-DD')}", -> "Save"
            span " "
            a ".btn.cancel", href: "##{@start.format('YYYY-MM-DD')}", -> "Cancel"

    initialize: ->      
      @bind "rendered", ->
        console.log "HELLO"
        $el = @$("input.title")
        $ul = $("<ul>", class: "refiner").hide().insertAfter($el)
        
        $el.on "focus", -> $ul.show()
        #$el.on "blur", -> $ul.hide()
        
        search = ->
          $ul.empty()

          regex = new RegExp("^" + $el.val() + "([^\/]*)", "i")
          _(timelog.entries.pluck("title")).chain()
            .filter((title) -> title.match(regex))
            .map((title) -> title.match(regex)[0])
            .unique()
            .each (match) ->
              $li = $("<li>")
              $sel = $("<a>", class: "select", text: match)
                .appendTo($li)
                .on "click", ->
                  $el.val(match)
                  $ul.hide()
              $refine = $("<a>", class: "refine", text: "/")
                .appendTo($li)
                .on "click", ->
                  $el.val(match + "/").focus()
                  search()
              $li.appendTo($ul)
        
        $el.on "keyup", _.throttle search, 100
        
        $start = @$("[name=start]")
        $end = @$("[name=end]")
        
        start = @model.getEarliestStart().nearestMinutes(6)
        end = @model.getLatestEnd().nearestMinutes(6)
        
        time = start.clone()
        
        while end.diff(time, "minutes") >= 0
          $start.append($("<option>", value: time.format("HH:mm"), text: time.format("HH:mm")))
          $end.append($("<option>", value: time.format("HH:mm"), text: time.format("HH:mm")))
          time.add("minutes", 6)
        
        defaultEnd = @model.get("end").clone()
        defaultEnd = start.clone().add("hours", 1) unless @model.id or start.diff(end, "hours", true) < 1
          
        $start.val(@model.get("start").format("HH:mm"))
        $end.val(defaultEnd.format("HH:mm"))

        $start.on "change", ->
          time = moment(start.format("YYYY-MM-DD") + " " + $start.val(), "YYYY-MM-DD HH:mm")
          oldEnd = $end.val()
          $end.empty()
          while time.diff(end, "minutes") <= 0
            $end.append($("<option>", value: time.format("HH:mm"), text: time.format("HH:mm")))
            time.add("minutes", 6)
          $end.val(oldEnd)
        
        
        $el.focus()
      $(@render().el).hide().appendTo("#pages")
      @model.bind "all", _.throttle(@render, 100)

    save: (e) ->
      date = @model.get("start").format("YYYY-MM-DD")
      @model.set
        title: @$("[name=title]").val()
        description: @$("[name=description]").val()
        start: moment(date + " " + @$("[name=start]").val(), "YYYY-MM-DD HH:mm")
        end: moment(date + " " + @$("[name=end]").val(), "YYYY-MM-DD HH:mm")
      
      console.log "Saving", @model.toJSON()
      
      if @model.id then timelog.entries.get(@model.id).save @model.toJSON()
      else timelog.entries.create @model.toJSON()

      #e.preventDefault()

    cancel: ->

  view = new Form(model: timelog.day.last())

  # Return public interface of page
  prepare: (date, cid) ->
    if block = timelog.day.getByCid(cid)
      console.log "BLOCK", block
      view = new Form(model: block)
    
  show: -> $(view.el).fadeIn()
  hide: -> $(view.el).fadeOut()#{start}", "YYYY-MM-DD HH:mm")
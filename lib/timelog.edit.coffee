lumbar.router.registerPage /^(\d\d\d\d-\d\d-\d\d)(?:@(\d\d:\d\d)|\?start=(\d\d:\d\d)&end=(\d\d:\d\d))$/, "edit", ->
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
              input ".xlarge.title", name: "title", autocomplete: "off", placeholder: "Path/of/activity", value: @title
              span ".help-block", "The path of your activity helps structure your time."
          div ".clearfix", ->
            label "Description"
            div ".input", ->
              textarea ".xlarge", name: "description", placeholder: "Describe how you spent your time...", -> @description
          div ".clearfix", ->
            div ".input", div ".inline-inputs", ->
              select ".mini", type: "time", name: "start", ->
              span "to"
              select ".mini", type: "time", name: "end", ->
          div ".actions", ->
            a ".btn.primary.save", href: "##{@start.format('YYYY-MM-DD')}", -> "Save"
            span " "
            a ".btn.cancel", href: "##{@start.format('YYYY-MM-DD')}", -> "Cancel"

    initialize: ->
      $(@render().el).hide().appendTo("#pages")
      @model.bind "all", _.throttle(@render, 100)
      
      @bind "rendered", =>
        $el = @$("input.title")
        $ul = $("<ul>", class: "refiner").hide().insertAfter($el)
        
        $el.on "focus", -> $ul.show()
        #$el.on "blur", -> $ul.hide()
        
        search = ->
          $ul.empty()

          regex = new RegExp("^" + $el.val() + "([^\/]*)", "i")
          _(timelog.blocks.pluck("title")).chain()
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
        
        start = @model.get("start").clone() or moment().clearTime()
        end = @model.get("end").clone() or moment()
        time = start.clone().hours(7)
        
        console.log "start", start.toString(), "end", end.toString(), time.diff(end, "minutes")

        while end.diff(time, "minutes") >= 0
          $start.append($("<option>", value: time.format("HH:mm"), text: time.format("HH:mm")))
          $end.append($("<option>", value: time.format("HH:mm"), text: time.format("HH:mm")))
          time.add("minutes", 6)
        
        $end.val(time.subtract("minutes", 6).format("HH:mm"))

        $start.on "change", ->
          time = moment(start.format("YYYY-MM-DD") + " " + $start.val(), "YYYY-MM-DD HH:mm")
          oldEnd = $end.val()
          $end.empty()
          while time.diff(end, "minutes") <= 0
            $end.append($("<option>", value: time.format("HH:mm"), text: time.format("HH:mm")))
            time.add("minutes", 6)
          $end.val(oldEnd)
        
        
        

    save: (e) ->
      date = @model.get("start").format("YYYY-MM-DD")
      @model.set
        title: @$("[name=title]").val()
        description: @$("[name=description]").val()
        start: moment(date + " " + @$("[name=start]").val(), "YYYY-MM-DD HH:mm")
        end: moment(date + " " + @$("[name=end]").val(), "YYYY-MM-DD HH:mm")
      
      console.log "Saving", @model.toJSON()
      
      if @model.id then timelog.blocks.get(@model.id).save @model.toJSON()
      else timelog.blocks.create @model.toJSON()

      e.preventDefault()

      lumbar.router.navigate("#" + @model.get("start").format("YYYY-MM-DD"), true)

    cancel: ->



  view = new Form(model: new timelog.Block)

  # Return public interface of page
  prepare: (date, id, start, end) ->
    view.model.clear(silent: true)
    if id
      console.log "ID", timelog.blocks.get("#{date}@#{id}").toJSON()
      view.model.set timelog.blocks.get("#{date}@#{id}").toJSON()
    else
      view.model.set
        start: moment("#{date} #{start}", "YYYY-MM-DD HH:mm")
        end: moment("#{date} #{end}", "YYYY-MM-DD HH:mm")
  show: -> $(view.el).fadeIn()
  hide: -> $(view.el).fadeOut()#{start}", "YYYY-MM-DD HH:mm")
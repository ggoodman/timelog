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
              input ".xlarge", name: "title", placeholder: "Path/of/activity", value: @title
              span ".help-block", "The path of your activity helps structure your time."
          div ".clearfix", ->
            label "Description"
            div ".input", ->
              textarea ".xlarge", name: "description", placeholder: "Describe how you spent your time...", -> @description
          div ".clearfix", ->
            div ".input", div ".inline-inputs", ->
              input ".mini", type: "text", name: "start", placeholder: "00:00", value: @start?.format("HH:mm")
              span "to"
              input ".mini", type: "text", name: "end", placeholder: "00:00", value: @end?.format("HH:mm")
          div ".actions", ->
            a ".btn.primary.save", href: "##{@start.format('YYYY-MM-DD')}", -> "Save"
            span " "
            a ".btn.cancel", href: "##{@start.format('YYYY-MM-DD')}", -> "Cancel"

    initialize: ->
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
  hide: -> $(view.el).fadeOut()
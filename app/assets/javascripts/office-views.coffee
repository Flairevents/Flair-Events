# GUI FOR OFFICE ZONE

# The page which uses this file must load the Google Maps library
# Shorthand:
$(document).ready(-> # make sure library has loaded
  window.gmaps   = google?.maps
  window.gmapevt = gmaps.event if gmaps)

#Ensures data is up to date, and that officer is still logged in, when user switches back to window.
#We use the 'first_focus' variable to see if the window is REALLY getting focus because the select2 element
#keeps firing the focus event
#$(document).ready(->
#  window.first_focus = true
#  window.onfocus = () ->
#    if (typeof @db != 'undefined') && window.first_focus == true
#      window.first_focus = false
#      @db.refreshData()
#  window.onblur = () ->
#    window.first_focus = true
#)

# The Office Zone has various selectable "Views" or sub-UIs,
#   each of which displays and allows the user to manipulate different data
# We have 1 CS class for each View, under app/assets/javascripts/office-views/
# In the Office Zone page, 1 instance of each View class is created (in inline JS),
#   and passed to a global ViewManager which holds them

# Each View has a "viewport" -- a DOM element where it displays its interface
# Each "viewport" element belongs to 1 and only 1 View
# No code outside the owning View should add, remove, or change the contents of
#   a viewport, nor should it attach event handlers to elements within the viewport
# The viewport belongs to the View alone

# However, the Office Zone page may pre-render some HTML in some of the viewports
# (see app/views/office/_events.html.haml for the initial contents of the Events View
#   viewport, _team.html.haml for Team View, and so on)

# Each View gets a reference to a 'DB' object, actually a DbProxy instance
# Each View pulls the data it needs from the DbProxy, and registers callbacks with
#   the DbProxy to be informed when data it is interested in changes
# Each View can make async requests to the server as needed
# If the server sends back new/changed DB records to any View, it should pass them
#   on directly to the DbProxy
# The DbProxy will call the registered callback functions (so the UI will be updated)

# Each View must respond to draw() -- it will be called when necessary

class ViewManager
  constructor: (@views) ->
    @showing = null

    @switchView = (name, tab) =>
      if @showing?
        @views[@showing].visible = false
      @showing = name
      tab.tab('show')
      $(tab.attr('href')).focus()
      @views[name].show() # tell new View that it is visible now

  # Switch from one View to another
  # Some Views have special code which must be run when leaving that view --
  #   and can even "veto" the change
  # (For example, if it has unsaved data)
  #
  # Another subtlety: we must make the new View visible BEFORE telling it that it is now visible
  # This is because of a problem with Google Maps
  # Every time we hide a Google Map and display it again, we need to tell it to resize itself
  # MapView does this, but it needs to *already* be visible for it to work
  #
  select: (name, tab) ->
    return if @showing == name

    if @showing?
      @views[@showing].msg('hide', {actor: Actor(
        hidden: =>
          @switchView(name, tab))})
    else
      @switchView(name, tab)

  # Display a view and send a message to it after it is visible
  #
  send: (view, msg, data={}) ->
    if @showing == name
      @views[view].msg(msg, data)
    else
      tab = $('#view-tabs a[href="#' + view + '"]')
      if @showing?
        @views[@showing].msg('hide', {actor: Actor(
          hidden: =>
            @switchView(view, tab)
            @views[view].msg(msg, data))})
      else
        @switchView(view, tab)
        @views[view].msg(msg, data)

  sendOnly: (view, msg, data={}) ->
    @views[view].msg(msg, data)

  selectedView: ->
    @views[@showing]

# Common superclass of all Views:
#
class View
  constructor: (@viewport) ->
    Actor(@)
    @visible = false
    @stale   = true

  show: ->
    return if @visible
    @visible = true
    if @stale
      @draw()
      @stale = false

  redraw: =>
    if @visible
      @draw()
      @stale = false
    else
      @stale = true

  draw: -> # default implementation does nothing

  hide: (data) ->
    # default implementation just says 'OK, I'm ready to hide'
    # but this can be overridden -- if view doesn't want to hide,
    #   it can simply never send back 'hidden' message
    # this is used to prevent active view from hiding until any edited data is
    #   saved on the server
    data.actor.msg('hidden')

  # find DOM node in the viewport by 'name' or ID
  node: (query) -> @viewport.node(query)

# export to global scope
window.ViewManager = ViewManager
window.View        = View

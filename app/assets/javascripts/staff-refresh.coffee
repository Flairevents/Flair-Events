window.refreshStaffZone = ->
  if document.visibilityState == 'visible'
    # if window.location.pathname == '/staff/events'
    #   refreshEvents()
    # if window.location.pathname == '/staff' && ($('#tab-upcoming-contracts.active').length > 0 || $('#tab-pending-contracts.active').length > 0)
    #   refreshContracts()
    if window.location.pathname == '/staff' && $('#tab-interview-signup.active').length > 0
      refreshOnlineInterviews()
    if window.location.pathname == '/staff' && $('#prospectStatusApplicant').length > 0
      refreshIfHired()

window.refreshIfHired = ->
  $.ajax({
      url: '/staff/get_hired_status',
      type: 'POST',
      success: (data, status, xhr) ->
        if $('#prospectStatusApplicant').length > 0 && data.status == 'EMPLOYEE'
          location.reload()
    })
      
window.refreshContracts = ->
  $.ajax({
    url: '/staff/refresh_contracts',
    type: 'POST',
    success: (data, status, xhr) ->
      updateNode({
        $targetNode: $('#tab-upcoming-contracts'),
        html: data['upcoming'],
        onupdate: () ->
          $headers = $('#tab-upcoming-contracts').find('.header')
          $headers.click((e) ->
            accordionHeaderClick(e))
          updateNumericBadge($('#badge-upcoming-contracts'), $headers.length)
      })
      updateNode({
        $targetNode: $('#tab-pending-contracts'),
        html: data['pending'],
        onupdate: () ->
          $headers = $('#tab-pending-contracts').find('.header')
          $headers.click((e) ->
            accordionHeaderClick(e))
          updateNumericBadge($('#badge-pending-contracts'), $headers.length)
      })
    })

window.refreshEvents = ->
  $.ajax({
    url: '/staff/refresh_events',
    data: { source: window.location.pathname},
    type: 'POST',
    success: (data, status, xhr) ->
      updateNode({
        $targetNode: $('#event-list-all'),
        html: data['contents'],
        onupdate: () ->
          $headers = $('#event-list-all').find('.header')
          $headers.unbind('click', accordionHeaderClick)
          $headers.bind(  'click', accordionHeaderClick)
          $eventListItems = $('.event-list__item')
          $eventListItems.unbind('click', highlightMapRegionListItemElementAttribute);
          $eventListItems.bind('click', highlightMapRegionListItemElementAttribute);
          $eventListItems.unbind('hover', highlightMapRegionListItemElementAttribute);
          $eventListItems.bind('hover', highlightMapRegionListItemElementAttribute);
        })
  })

window.refreshOnlineInterviews = ->
  $.ajax({
      url: '/staff/refresh_online_interview_tab',
      type: 'POST',
      success: (data, status, xhr) ->
        refreshInterviewFlexslider('#tab-interview-signup', '#tab-interview-signup_dummy', '#interview-flexslider', data['contents'])
        installDatePicker()
    })

# Since the flexslider modifies the DOM, it will always appear as modified
# So, store a copy of the calendar in the dummyContainer, and do a complete update if the new contents are different than the dummy.
window.refreshInterviewFlexslider = (containerSelector, dummyContainer, selector, contents) ->
  container = $(containerSelector)
  # Temporarily freeze height so that nothing below jumps out of place while refreshing.
  $(containerSelector).height($(containerSelector).height())
  slider = $(selector).data('flexslider')
  if typeof slider isnt 'undefined'
    currentSlide = slider.currentSlide
    animationSpeed = slider.vars.animationSpeed
  updateNode({
    $targetNode: $(dummyContainer),
    html: contents
    onupdate: () =>
      $(containerSelector).html(contents)
      if $(selector).length > 0
        $(selector).flexslider({
          animation: "slide",
          slideshow: false,
          nextText: "",
          prevText: "",
          start: (slider) ->
            container.height('auto')
        })
        slider = $(selector).data('flexslider');
        if typeof slider isnt 'undefined'
          if currentSlide < slider.count
            slider.vars.animationSpeed = 0
            slider.flexAnimate(currentSlide)
            slider.vars.animationSpeed = animationSpeed
    noupdate: () =>
      $(containerSelector).height('auto')
  })

window.updateNumericBadge = ($badge, n) ->
  if n > 0
    $badge.html(n) unless $badge.html() == n
    $badge.show()
  else
    $badge.hide()

##### Given an options hash with the following:
##### $targetNode:         The node you want to update
##### html:                The replacement innerHTML for the node
##### onupdate [optional]: The function you want to call if the node was updated (ie. rebind events)
##### This function compares the node innerHTML with the replacement HTML
##### If they are different, it updates ONLY the differences in the target node
##### If update was done, it triggers the optional 'onupdate' function
window.updateNode= (options) ->
  throw "$targetNode is undefined" if typeof options['$targetNode'] is undefined
  throw "html is undefined"        if typeof options['html'] is undefined

  $targetNode = options['$targetNode']
  if $targetNode.length > 0
    #Make a new node with the same attributes as the target node
    $newNode = $("<div></div>")
    for item in Array::slice.apply($targetNode[0].attributes)
      $newNode[0].setAttribute(item.name, item.value)

    #Fill the new node with the desired html
    $newNode.html(options['html'])
    $newNode.html(options['html'])

    #Find the differences between the target and new node
    dd = new diffDOM()
    diff = dd.diff($targetNode[0], $newNode[0])

    #If there are differences, update the targetNode, only updating the child nodes that actually changed
    if diff.length > 0
      dd.apply($targetNode[0], diff)
      options['onupdate']() if typeof options['onupdate'] is 'function'
    else
      options['noupdate']() if typeof options['noupdate'] is 'function'

$(document).ready ->
  # This sometimes throws a ReferenceError: 'refreshStaffZone' is not defined.
  # TODO: Setup a stack trace
  setInterval(refreshStaffZone, 3*60*1000)
  return
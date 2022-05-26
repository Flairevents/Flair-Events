# Added to fix turbolinks anchor issue
# https://github.com/turbolinks/turbolinks/issues/75#issuecomment-244915109
linkTargetsAnchorOnSamePage = (link) ->
  href = link.getAttribute('href')

  return true if href.charAt(0) == '#'

  if href.match(new RegExp('^' + window.location.toString().replace(/#.*/, '') + '#'))
    return true
  else if href.match(new RegExp('^' + window.location.pathname + '#'))
    return true

  return false
  
$(document).on 'turbolinks:click', (event) ->
  if linkTargetsAnchorOnSamePage(event.target)
    return event.preventDefault()

#Not Needed because In the Staff Zone we are linking to spans with class anchor that take care of the offset.
#$(document).on 'turbolinks:load', (event) ->
#  if window.location.hash
#    $element = $('a[name="' + window.location.hash.substring(1) + '"]')
#    $('html, body').scrollTop($element.offset().top)

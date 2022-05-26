##### Asynchronous Social loader for use with turbolinks
##### https://www.benoitz.com/p/facebook-sdk-and-turbolinks-5-compatibility

window.FacebookSDK =
  load: ->
    @fbRoot = document.getElementById('fb-root')
    return if @fbRoot == null
    if FB? && @fbRoot.children.length == 0
      @fbRoot.innerHTML = @fbRootSaved
    return FB.XFBML.parse() if FB?
    $.ajax '//connect.facebook.net/en_GB/sdk.js',
      dataType: 'script'
      cache: true
      success: => @init()

  init: ->
    FB.init(xfbml: true, version: 'v3.2')
    @fbRootSaved = @fbRoot.innerHTML

#Inspired by above and http://reed.github.io/turbolinks-compatibility/twitter.html
window.TwitterSDK =
  load: ->
    $.ajax "//platform.twitter.com/widgets.js",
      dataType: 'script'
      cache: true
      success: => @init()
  init: ->
    twttr.widgets.load()
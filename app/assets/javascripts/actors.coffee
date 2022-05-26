
messageQ  = []
reentrant = false
messageLog = []
debug = false

sendMessage = (actor, msg, data, options={}) ->
  return false unless actor[msg]?

  if debug
    console.info('message: "' + msg + '" to: ')
    console.info(actor)
    console.info(data)
    console.info("\n")

  messageLog.push({actor: actor, message: msg, data: data})
  if messageLog.length > 10
    messageLog.shift()

  if reentrant
    messageQ.push(-> actor[msg](data))  
  else
    fn = ->
      reentrant = true
      try
        actor[msg](data)
      finally
        try
          # if any handler on the queue throws an exception, we won't clear the rest!
          # this isn't ideal but I haven't come up with anything better yet
          while handler = messageQ.shift()
            handler()
        finally
          reentrant = false
    if options['synchronous'] == true then fn() else setTimeout(fn, 0)
  true

window.Actor = (obj) ->
  obj.msg = (message, data={}, options={}) ->
    sendMessage(obj, message, data, options)
  obj

window.Tee = (actors...) ->
  msg: (message, data={}) ->
    actor.msg(message, data) for actor in actors

window.NullActor = # call it Sink?
  msg: (message, data={}) ->
    null

window.actorLog = ->
  JSON.stringify(messageLog, undefined, 2)
window.printActorLog = ->
  for message in messageLog
    console.info(message)

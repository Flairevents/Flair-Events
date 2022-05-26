# FORMATTING OUTPUT

window.padDigits = (number,digits) ->
  Array(Math.max(digits - String(number).length + 1, 0)).join(0) + number

window.printDate = (date) ->
  if date? && date != ''
    padDigits(date.getDate(), 2) + '/' + padDigits(date.getMonth()+1, 2) + '/' + date.getFullYear()
  else
    ''

window.parseDate = (dateString) ->
  dateRegexp = /[0-9]+\/[0-9]+\/[0-9]+$/g;
  match = dateRegexp.exec(dateString);
  if match.length == 0 then return null
  parts = match[0].split("/");
  date = new Date(Number(parts[2]), Number(parts[1]) - 1, Number(parts[0]));
  if date instanceof Date && !isNaN(date) then date else null

window.printDateDD = (date) ->
  if date? && date != ''
    padDigits(date.getDate(), 2)
  else
    ''

window.printDateDDMM = (date) ->
  if date? && date != ''
    padDigits(date.getDate(), 2) + '/' + padDigits(date.getMonth()+1, 2)
  else
    ''

window.printDateDDMMYY = (date) ->
  if date? && date != ''
    padDigits(date.getDate(), 2) + '/' + padDigits(date.getMonth()+1, 2) + '/' + date.getFullYear().toString().substr(2,2)
  else
    ''

window.printDateDOW = (date) ->
  ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.getDay()]

window.printDateWithDOW = (date) ->
  if date? && date != ''
    printDateDOW(date) + ' ' + printDate(date)
  else
    ''

window.printTime = (date) ->
  if date? && date != ''
    padDigits(date.getHours(), 2) + ':' + padDigits(date.getMinutes(), 2)

window.printDateTime = (date) ->
  if date? && date != ''
    printDate(date) + ' ' + printTime(date)

window.printDateTimeWithDOW = (date) ->
  printDateWithDOW(date) + ' ' + printTime(date)

window.printDateDDMMWithDOW = (date) ->
  if date? && date != ''
    printDateDOW(date) + ' ' + printDateDDMM(date)
  else
    ''

window.printDateDDMMYYWithDOW = (date) ->
  if date? && date != ''
    printDateDOW(date) + ' ' + printDateDDMMYY(date)
  else
    ''

window.printDateSpan = (date1, date2) ->
  if date1.getTime() == date2.getTime()
    printDateDDMMYY(date1)
  else if date1.getFullYear() == date2.getFullYear()
    if date1.getMonth() == date2.getMonth()
      printDateDD(date1) + '-' + printDateDDMMYY(date2)
    else
      printDateDDMM(date1) + '-' + printDateDDMMYY(date2)
  else
    printDateDDMMYY(date1) + '-' + printDateDDMMYY(date2)

window.printSortedEventDates = (event_dates) ->
  dateString = ''
  index = 0
  for event_date in event_dates
    date = event_date.date
    next_date = event_dates[index+1]?.date
    date_after_next = event_dates[index+2]?.date

    if index == 0
      dateString = printDateDDMMWithDOW(date)
    else if index > 0 && index == event_dates.length - 1
      dateString += ' - '
      dateString += printDateDDMMWithDOW(date)
    index = index + 1
  dateString

window.printTaxWeek = (tax_week) ->
  "#{padDigits(tax_week.week, 2)}: #{window.printDate(tax_week.date_start)} - #{window.printDate(tax_week.date_end)}"

window.printTaxYear = (tax_year) ->
  "#{tax_year.date_start.getFullYear()}-#{tax_year.date_end.getFullYear()}"

window.printTaxYearAndWeek = (tax_year, tax_week) ->
  "#{printTaxYear(tax_year)} #{printTaxWeek(tax_week)}"

window.printOrdinal = (i) ->
  if (i > 3 && i < 21)
    return  i+'th'
  switch (i % 10)
    when 1 then return i+'st'
    when 2 then return i+'nd'
    when 3 then return i+'rd'
    else        return i+'th'

window.printShift = (shift) ->
  "#{printDateDOW(shift.date)} #{printOrdinal(shift.date.getDate())} (#{shift.time_start}-#{shift.time_end})"

window.printLocation = (location) ->
  if (location.type != 'REGULAR' && !(location.name.match(/SPARE|FLOATER/i))) then "#{location.name} (#{titleCase(location.type)})" else location.name

window.printAssignment = (assignment, job_id=null, location_id=null) ->
  (if assignment.job_id == job_id then '' else "#{@db.findId('jobs', assignment.job_id).name} @ ") +
  (if assignment.location_id == location_id then '' else "#{printLocation(@db.findId('locations', assignment.location_id))} : ") +
  "#{printShift(@db.findId('shifts', assignment.shift_id))}"

window.printAssignmentWithStats = (assignment, job_id=null, location_id=null) ->
  if assignment.n_confirmed > 0
    printAssignment(assignment, job_id, location_id) + " #{assignment.n_confirmed}✓ #{assignment.n_assigned}/#{assignment.staff_needed}"
  else
    printAssignment(assignment, job_id, location_id) + " #{assignment.n_assigned}/#{assignment.staff_needed}"

window.printTimeClockReport = (time_clock_report) ->
  user = getUser(time_clock_report.user_type, time_clock_report.user_id)
  "#{printDateWithDOW(time_clock_report.date)}: #{user.last_name}, #{user.first_name}"

window.getUser = (userType, userId) ->
  table = switch userType
    when 'Prospect'      then 'prospects'
    when 'Officer'       then 'officers'
    when 'ClientContact' then 'client_contacts'
    else throw "Unsupported User Type: #{userType}"
  db.findId(table, userId)

window.titleCase = (str) ->
  str.toLowerCase().split(' ').map((word) ->
    word.replace(word[0], word[0].toUpperCase())
  ).join(' ')

window.locationSort = (a,b) ->
  compare(printLocation(a), printLocation(b))

window.locationByEarliestShiftSort = (a,b) ->
  if ((result = shiftSort(@db.findId('shifts', a.earliest_shift_id), @db.findId('shifts', b.earliest_shift_id))) != 0) then return result
  locationSort(a, b)

window.shiftSort = (a,b) ->
  if ((result = compare(a.date, b.date)) != 0) then return result
  if ((result = compare(padDigits(a.time_start, 5), padDigits(b.time_start, 5))) != 0) then return result
  if ((result = compare(padDigits(a.time_end, 5),   padDigits(b.time_end, 5)))   != 0) then return result
  0

window.assignmentSort = (a,b) ->
  aShift = @db.findId('shifts', a.shift_id)
  bShift = @db.findId('shifts', b.shift_id)
  if ((result = compare(aShift.date, bShift.date)) != 0) then return result
  if ((result = locationSort(@db.findId('locations', a.location_id),  @db.findId('locations', b.location_id))) != 0) then return result
  if ((result = compare(padDigits(aShift.time_start, 5), padDigits(bShift.time_start, 5))) != 0) then return result
  if ((result = compare(padDigits(aShift.time_end, 5), padDigits(bShift.time_end, 5))) != 0) then return result
  compare(@db.findId('jobs', a.job_id).name, @db.findId('jobs', b.job_id).name)

window.gigAssignmentSort = (a,b) ->
  assignmentSort(@db.findId('assignments', a.assignment_id), @db.findId('assignments', b.assignment_id))

window.lastNameFirstNameSort = (a,b) ->
  if ((result = compare(a.last_name, b.last_name)) != 0) then return result
  compare(a.first_name, b.first_name)

window.eventDateSort = (a,b) ->
  compare(a.date, b.date)

window.timesheetEntrySort = (a,b) ->
  aGigAssignment = @db.findId('gig_assignments', a.gig_assignment_id)
  bGigAssignment = @db.findId('gig_assignments', b.gig_assignment_id)
  if ((result = lastNameFirstNameSort(@db.findId('prospects', @db.findId('gigs', aGigAssignment.gig_id).prospect_id),
                             @db.findId('prospects', @db.findId('gigs', bGigAssignment.gig_id).prospect_id))) != 0) then return result
  if ((result = compare(@db.findId('events', @db.findId('gigs', aGigAssignment.gig_id).event_id).name,
                        @db.findId('events', @db.findId('gigs', bGigAssignment.gig_id).event_id).name)) != 0) then return result
  gigAssignmentSort(aGigAssignment, bGigAssignment)

window.timeClockReportSort = (a,b) ->
  if ((result = compare(a.date, b.date)) != 0) then return result
  aProspect = @db.findId('gig_assignments', a.prospect_id)
  bProspect = @db.findId('gig_assignments', b.prospect_id)
  if ((result = compare(aProspect.last_name, bProspect.last_name)) != 0) then return result
  if ((result = compare(aProspect.first_name, bProspect.first_name)) != 0) then return result
  0

window.payweekSort = (a,b) ->
  lastNameFirstNameSort(@db.findId('prospects', a.prospect_id), @db.findId('prospects', b.prospect_id))

window.eventSortByEventDates = (taxWeekId, a, b) ->
  today = getToday()
  datesA = a.event_dates[taxWeekId]
  datesB = b.event_dates[taxWeekId]
  firstDateA = datesA[0].date
  firstDateB = datesB[0].date
  lastDateA = datesA[datesA.length-1].date
  lastDateB = datesB[datesB.length-1].date
  if ((result = compare(lastDateA >= today, lastDateB >= today)) != 0) then return result
  if ((result = compare(firstDateA, firstDateB)) != 0) then return result
  0

window.prospectName = (prospect) ->
  if prospect.client_id?
    "#{prospect.last_name}, #{prospect.first_name} (#{window.db.findId('clients', prospect.client_id).name})"
  else
    "#{prospect.last_name}, #{prospect.first_name}"

window.subcodeFromRecord = (record) ->
  record.post_code && record.post_code.split(' ')[0]

# Whatever 'record' is, it must have a 'post_code' property
# It might be an Event, a Prospect, or something else
window.postAreaForRecord = (record) ->
  tbl     = @db.lookupTable('post_areas', 'subcode')
  subcode = subcodeFromRecord(record)
  subcode && (codes = tbl[subcode]) && codes[0]

window.regionForRecord = (record) ->
  record.region_id && window.Regions[record.region_id]

window.coordinatesForRecord = (record) ->
  post_area = postAreaForRecord(record)
  post_area && [post_area.latitude, post_area.longitude]

window.compare = (a,b) ->
  if (a < b) then -1 else (if (a > b) then 1 else 0)

##### Move undefined to end of list
window.compareDefined = (a,b) ->
  if (a == undefined && b == undefined) then 0 else (if a == undefined then 1 else -1)

window.escapeHTML = (string) ->
  pre = document.createElement('pre')
  text = document.createTextNode(string)
  pre.appendChild(text)
  pre.innerHTML

window.utcToLocal = (utc) ->
  utc && new Date(utc.getTime() + (utc.getTimezoneOffset()*60000))

window.localToUtc = (local) ->
  local && new Date(local.getTime() - (local.getTimezoneOffset()*60000))

window.msToMin = (n) ->
  n/60000

window.msToHrs = (n) ->
  n/3600000

window.minToHrs = (n) ->
  n/60

# CLASS/OBJECT METAPROGRAMMING

window.delegate = (from, to, methods...) ->
  for method in methods
    if to[method]
      do (method) ->
        from[method] = (args...) -> to[method](args...)
#    else
#      throw new Error("Can't delegate #{method} method to #{to} -- it has no method with that name")

window.chain = (obj, method, func) ->
  if original = obj[method]
    obj[method] = (args...) ->
      original.apply(obj, args)
      func.apply(obj, args)
  else
    obj[method] = func
  obj[method]

window.prepend = (obj, method, func) ->
  if original = obj[method]
    obj[method] = (args...) ->
      func.apply(obj, args)
      original.apply(obj, args)
  else
    obj[method] = func
  obj[method]

window.mergeAndUniquifyArrays = (a, b) ->
  hash = {}
  ret = []

  for e in a
    if !hash[e]
      hash[e] = true
      ret.push(e)

  for e in b
    if !hash[e]
      hash[e] = true
      ret.push(e)

  return ret

window.getNewElements = (a, b) ->
  hash = {}
  ret = []

  for e in a
    hash[e] = true

  for e in b
    if !hash[e]
      ret.push(e)

  return ret

# COLLECTIONS

Array::findIndex = (func) ->
  for item, index in @
    return index if func(item)
  null

Array::findItem = (func) ->
  for item in @
    return item if func(item)
  null

Array::hasItem = (item) ->
  for _item in @
    return true if _item == item
  false

# This uses backticks to take advantage of Javascript == (Comparison with type coercion)
# (By default, coffeescript converts all == to Javascript ===)
# Useful for comparing integers to their equivalent strings in dropdowns.
Array::hasItemWithCoercion = (item) ->
  for _item in @
    return true if `_item == item`
  false

Array::uniqueItems = ->
  result = []
  seen   = {}
  for item in @
    unless seen[item]
      seen[item] = true
      result.push(item)
  result

Array::pushIfUnique = (val) ->
  @.push(val) if @.indexOf(val) < 0

Array::delete = (val) ->
  index = @.indexOf(val);
  @.splice(index, 1) if (index >= 0)

String::width = () ->
  window.Ruler ?= do () ->
    $('<span id="ruler" style="visibility: hidden; white-space: nowrap; font: 1em system-ui"></span>').appendTo($('body'))
    document.getElementById('ruler')
  Ruler.innerHTML = @;
  Ruler.offsetWidth;

# GUI

window.buildSelect = (options) ->
  options.name || throw "Must Specify Name"
  "<select class='" + (options.class || '') + " form-control' name='" + options.name + "' " + (options.otherHtml || '') + (if options.multiple then " multiple" else "") + ">" + buildOptions(options.options, (options.selected || '')) + "</select>"

# Use this one for select tags that we will turn into select2. We don't want the 'form-control' class on those
window.buildSelect2 = (options) ->
  options.name || throw "Must Specify Name"
  "<select class='" + (options.class || '') + " change-on-set-val' name='" + options.name + "' " + (options.otherHtml || '') + (if options.multiple then " multiple" else "") + ">" + buildOptions(options.options, (options.selected || '')) + "</select>"

# Use this one for multiselect
window.buildMultiSelect = (options) ->
  options.name || throw "Must Specify Name"
  "<select class='" + (options.class || '') + " form-control' name='" + options.name + "' " + (options.otherHtml || '') + " multiple" + ">" + buildOptions(options.options, (options.selected || '')) + "</select>"

window.buildTextInput = (options) ->
  options.name || throw "Must Specify Name"
  "<input type='text' class='" + (options.class || '') + (if options.otherHtml?.includes("readonly") then "'" else " form-control'") + "name='" + options.name + "' value='" + sanitizeText(options.value) + "' " + (options.otherHtml || '') + ">"

window.buildHiddenInput = (name, value) ->
  "<input type='hidden' name='" + name + "' value='"+ value + "'/>"

window.buildAutosizeTextarea = (options) ->
  options.name || throw "Must Specify Name"
  ["<textarea class='" + (options.class || '') + " form-control' rows='1' name='" + options.name + "'>" + sanitizeText(options.value) + "</textarea>", -> autosize($("textarea[name='" + options.name + "']"))]


# An unchecked checkbox will not serialize. Therefore we use a hidden input to represent false when unchecked.
# If the checkbox is checked, then it will take priority over the hidden input value
window.buildCheckbox = (options) ->
  options.name || throw "Must Specify Name"
  "<input type='hidden' value='0' name='" + options.name + "'><input type='checkbox' class='" + (options.class || '') +  "' name='" + options.name + "' value='1'"  + (if options.checked then " checked='checked'" else '') + "'>"

window.buildDeleteLink = (id, url) ->
  if id < 0
    delete_link = ''
  else
    delete_link = $("<a style='color:red' href='javascript:void(0)'>X</a>")
    delete_link.click(=> ServerProxy.sendRequest("/office/"+url+"/" + id, {}, ErrorOnlyPopup, @db) if id != -1)

window.sanitizeText = (text) ->
  ((text && text.toString()) || '').replace("'", "&apos;")

window.escapeText = (text) ->
  ((text && text.toString()) || '').replace("'", "\\'")

window.buildOptions = (options, selected) ->
  result = ""
  selected = [selected] unless Array.isArray(selected)

  for option in options
    if (typeof option[0] == 'string') && Array.isArray(option[1])
      result += "<optgroup label = \"#{option[0]}\">"
      result += buildOptions(option[1], selected)
      result == "</optgroup>"
    else
      result += "<option value='" + option[1] + "'"
      result += " selected='selected'" if selected.hasItemWithCoercion(option[1])
      for key, value of option[2]
        result += " " + key + "='" + value + "'"
      result += ">" + option[0] + "</option>"
  result

window.warningForOtherManagers = (requestIds) ->
  managerIds = []
  events = []
  requestIds.map((rid) ->
    gr = @db.findId('gig_requests', rid)
    event = @db.findId('events', (gr.event_id))
    events.push(event)
    managerIds.push(@db.findId('events', (gr.event_id)).office_manager_id)
  )
  otherOfficeManager = []
  eventNames = []
  officeManagerNames = []
  currentOfficer = Number($('.officer_id').text())
  i = 0
  while i < managerIds.length
    if managerIds[i] != currentOfficer && events[i].is_restricted == true
      eventNames.push(events[i].name)
      officeManagerNames.push(@db.findId('officers', events[i].office_manager_id)?.first_name || '')
    i = i + 1
  is_confirm = true
  if eventNames.length > 0
    eventNames = eventNames.slice(0, eventNames.length).join(', ')
    officeManagerNames = officeManagerNames.uniqueItems().slice(0, officeManagerNames.length).join(', ')
    message = "Candidate selection restricted. Speak to " + officeManagerNames + " if your candidate is a knockout and should be considered."
    message
  else
    ''

window.disableLink = (link) ->
  link.addClass('disabled')
  unless link.disabledBefore
    link.click(->
      if link.hasClass('disabled')
        return false)
    link.disabledBefore = true

window.enableLink = (link) ->
  link.removeClass('disabled')

window.sendEmail = (template, prospects) ->
  if prospects.length > 1000
    alert("Sorry, you can't send a bulk e-mail to more than 1000 recipients at once. (Right now " + prospects.length + " are selected.)")
    return
  else if prospects.length == 1
    url  = 'mailto:' + prospects[0].email
    url += '?bcc=' + window.currentOfficerEmail
  else
    url  = 'mailto:' + window.currentOfficerEmail
    url += '?bcc=' + prospects.map((p) -> p.email).join(',')
  url += '&subject=' + encodeURI(template.key)
  url += '&body=' + encodeURI(template.contents)
  window.open(url, '_blank')

window.fillInput = (input, value) ->
  if input.tagName?
    if input.tagName == 'INPUT' and input.type == 'checkbox'
      input.checked = value
    else
      $(input).val(value)
  else if input instanceof tinymce.Editor
    input.setContent(value || '') # TinyMCE throws exception if given 'null'
  else
    throw new Error("Unexpected object type passed to fillInput")
  $(input).change() if input.className.split(' ').includes('change-on-set-val')

window.fillDateInput = (input, value) ->
  throw "fillDateInput requires a jQuery Object" unless input instanceof jQuery
  input.datepicker('setDate', value || '')

showReasonCBWithEmailAndLog = (fnLog, email, createlog, cancelCB) ->
  params = {}
  params['lognote'] = $('#removeProspectLogNote').val() if $('#removeProspectLogNote').length > 0 && $('#removeProspectLogNote').val() != ''
  params['reason']  = $('#removeProspectReason').val()  if $('#removeProspectReason').val() != ''
  params['send_email'] = true if email == true
  if (!createlog && params['reason']) || (params['reason'] && params['lognote'])
    fnLog(params)
  else
    if !params['reason'] || !createlog
      bootbox.alert("Sorry, you must enter a reason. Please try again.")
    else
      bootbox.alert("Sorry, you must enter a reason and a lognote. Please try again.")
    cancelCB() if cancelCB

showReasonCBWithLog = (fnLog, email, createlog, cancelCB) ->
  params = {}
  params['lognote'] = $('#removeProspectLogNote').val() if $('#removeProspectLogNote').length > 0 && $('#removeProspectLogNote').val() != ''
  params['reason']  = $('#removeProspectReason').val()  if $('#removeProspectReason').val() != ''
  if !createlog || params['lognote']
    fnLog(params)
  else
    bootbox.alert("Sorry, you must enter a lognote. Please try again.")
    cancelCB() if cancelCB

showReasonCB = (fnLog, email, createlog, cancelCB) ->
  fnLog({})


window.showReasonDialog = (task, fnRmv, options={}) =>
  message = ''

  reasons = {
    'Biometric Card': "Biometric card - In addition to the picture page on your passport we also require the front and back images of your Biometric Card.",
    'Cancelled': "Thank you for cancelling this event, it now allows us to offer the work to someone else and stop emailing you! Much appreciated. Did you know you can also login to your staff profile and remove yourself from events right up until 1 week before? Hope to see you at other events.",
    'Cancelled Within 18 Hours of the Event': "You contacted us under 18 hours before the start of your shift and while we appreciate the communication, it is hard to find a replacement at such short notice. If possible, please can you consider giving us at least a 24hrs notice period (morning office hours one day before) to offer the work to others and find your replacement? Please note our system now records last minute cancellation to assist us in monitoring the individuals we select for certain contracts.",
    'Fully Staffed': "Thank you for applying to work this event contract. Unfortunately, this event is now full and we are no longer taking new applicants at this time. We do however open reserve lists to cope with last minute changes. If you would like to be placed on the reserve list, simply let us know.",
    'Incorrect Documents Provided': "You have not provided us with the correct documentation. Please upload the following:"+ "\\r\\n" +"Clear photographs of the front cover and photo page of your passport"+ "\\r\\n" +"Or"+ "\\r\\n" +"Full birth certificate and proof of national insurance"+ "\\r\\n" +"Please ensure the images are flat, in colour and with all the information is fully visible and avoid a photo flash as this can create a shine.Feel free to call our office if you have questions 0161 241 2441",
    'Low Performance Ratings': "We have noted at previous events you did not really perform to a quality standard, as a team leader has marked your working ethics and/or job enthusiasm as low. While we may still offer you work at a different contract to come and prove you have the skills to match our teams, we currently cannot consider you for this team. If you feel these details are wrong in any way, please feel free to contact our office as we would be happy to discuss your involvement in future events.",
    'Missing Information': "Please ensure that any/all text located on the document is clear and visible. Make sure all four corners of the document are in the scan or photo frame.",
    'Full Colour ID': "Full colour images - unfortunately we cannot accept black and white images or \\\'copies of copies.\\\'",
    'No Bar Experience': "This event requires experienced bar staff and unfortunately we feel you do not meet this criteria. Due to the nature of this event and the commitment we have made to the client, we cannot make exceptions on this and any inexperienced staff will stand out.  If you do have bar experience and we are just not aware of it, please contact the office ASAP to discuss. Alternatively you can update your employee profile with relevant work experience via your staff zone. Keeping us informed of your skills helps gain you the job roles you want.",
    'No Confirmation of Interest':  "We have just taken you off this event contract as we have not heard from you as requested. Please be aware we record how many times you fail to communicate with us concerning your pending contracts. As soon as you are aware you no longer wish to commit please either email us direct or visit your staff zone and remove yourself from any pending events. This will also reduce the amount of emails you receive from us.",
    'No Confirmation - Gentle': "We have temporarily removed you off this event contract until we get the chance to confirm your attendance and agreed shifts.  If you are still keen to work, but have just not had the chance to reply, please let us know ASAP so we can jump you back from the ‘Spare list’ to working.",
    'No ID as Required': "We have had to take you off this event as you have failed to uploaded a requested copy of valid ID. It is a requirement under UK employment law for all employers to hold a copy of valid ID for the duration of a person’s employment. If you can get a copy of your ID to us before the event starts, please contact the office immediately and we can reconsider your position.",
    'No Show': "We have noted you failed to show for work or offer any warning by cancelling your attendance. While we understand factors may influence your reasons to not work you must also understand we need loyal and committed employees as part of the Flair community. We have recorded this negative show upon a second time you would be removed from all pending contracts and could be deactivated from our database. Please give our office at least 24hrs notice if unable to work." + "\\r\\n" + "\\r\\n" + "If you believe we have jumped to the wrong conclusion, please contact our office immediately so we can rectify the situation.",
    'Out of Date': "Out of Date Working Visa / Work Permit. To enable Flair to offer you any future event contract we require you to upload your new valid right to work documents via your staff zone.",
    'Out of Focus': "Out of focus - please ensure that all documents are clearly visible, held down flat and unaffected by the flash.",
    'Poor Performance': "Due to the nature of this particular contract we are seeking a team who have perfomed well at previous events. Unfortunately, in the past you have not demonstrated positive working ethics and as a result you have been marked as either a 1 or 2 out of 5. While we may still offer you work at other events to come and prove you are worth employing, we currently cannot consider you for this particular team.",
    'Reduction of Staffing Numbers': "Sorry to disappoint you but the client has just reduced their staffing requirements at this event. Therefore, currently we are unable to offer you work, but we have placed your work request onto a reserve list. Should anything change we will reach out straight away to see if your still available.",
    'Travel Distance': "We have your registered address as quite some distance from this event. If you have a plan for your travel, like you\\\'re already in the area, staying with friends, car sharing then please contact our office and we will be happy to reconsider your request." + "\\r\\n" + "\\r\\n" + "Google Maps is a great source of information when making travel plans and your staff profile indicates how far your registered address is from any event venue.",
    'Unmatched Name': "Your first name or surname does not match your ID - If you have had a change of name then please provide us with further evidence such as a marriage certificate or deed pole document along with your ID.",
    'Unmatched Nationality': "Nationality - Your nationality does not match that of your ID. Can you please log onto your staff profile and update your information.",
    'Unsuccessful Work Request': "Your request to work at this event has been unsuccessful at this time. Reasons can be a mixed bag from the time of your request against our office teams management of the event and pool of applicants. We have listed a few common reasons:" + "\\r\\n" +  "• Small team focus" + "\\r\\n" + "• Client requesting returning crew" + "\\r\\n" + "• Travel distance against total wages" + "\\r\\n" + "• Match of skills to required jobs positions" + "\\r\\n" + "• Flair ratings from past events" + "\\r\\n" + "• Drop in requested numbers against volume of applicants" + "\\r\\n" + "\\r\\n" + "Should you be keen to go on the \\\'stand-by\\\' list, just in case of any last minute changes to requirements, please email us to let us know.",
    'Unsuitable for this Event': "You have been removed off this event for one of the two reasons stated below:" + "\\r\\n" + "1) This event has a very specific staffing criterion which we feel you currently do not meet in accordance to your profile. Please ensure that your profile is up to date and represents your skills and experience otherwise you could continue to miss out on work that you are in fact more than suitable for." + "\\r\\n" + "2) Due to the nature of this event we are only accepting staff members who are aged 18 or above. This does not mean however that you are unsuitable for other events and we will consider your application based on individual and client requirements.",
    'Event ‘Spare’ Status': "Your work request is currently being held on our ‘Spare list’ for this event contract. Your request is valued, and we will be in touch as soon as confirmed shifts become available.  We understand you may take work opportunities elsewhere but let’s hope we can catch you in time!",
    'Invalid Share Code': "The Share code you have entered is invalid and cannot be verified. Could you please re-check and re-enter the details via your staff profile. (Generate your share code here View and prove your immigration status)" + "\\r\\n" + "If you have a VIGNETTE in your passport and unable to use the share code service *" + "\\r\\n" + "Please email stating the reason you can’t use the site -"+ "\\r\\n" +"Clear photographs of the front cover and photo page of your passport"+ "\\r\\n" +"Proof of your national insurance number"+ "\\r\\n" +"A clear photograph of your visa inside your passport"+ "\\r\\n" +" Feel free to call our office if you have questions 0161 241 2441"
  }

  createlog = !options.hasOwnProperty('skip_log')

  if options.hasOwnProperty('preMessage')
    message += options["preMessage"] + '
      <br>
      <br>'

  message += "Enter a log note:<br><textarea name='log-note' class='logNote form-control' id='removeProspectLogNote'>#{options['logNote']||''}</textarea>" if createlog

  message += "Enter a reason:
    <br><textarea name='reason' class='reasonText form-control' id='removeProspectReason'>#{options['reason']||''}</textarea>"
  message += '<div class="btn-group" id="standard-reply">
      <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">
        Standard Reply <span class="caret"></span>
      </button>
      <ul class="dropdown-menu" role="menu">'
  types = if options.hasOwnProperty('id_messages')
    ['Biometric Card', 'Full Colour ID', 'Incorrect Documents Provided', 'Out of Date', 'Out of Focus', 'Missing Information', 'Unmatched Name', 'Unmatched Nationality', 'Invalid Share Code']
  else
    ['Cancelled', 'Cancelled Within 18 Hours of the Event', 'Fully Staffed', 'No Bar Experience', 'No Confirmation of Interest', 'No Confirmation - Gentle', 'No ID as Required', 'No Show', 'Poor Performance', 'Reduction of Staffing Numbers', 'Travel Distance', 'Unsuccessful Work Request', 'Unsuitable for this Event', 'Event ‘Spare’ Status']
  for type in types
    alert("#{type} is not a valid reason") unless reasons[type]
    message += '<li><a href="#" onclick="fillInText(\''+type+'\')">'+type+'</a></li>'
  message += '
      </ul>
    </div>'

  message += '<div class="checkbox checkbox-inline"></div>' if createlog

  message +=  '<script>
      function fillInText(type) {
        switch(type) {'

  for type, reason of reasons
    message += 'case \''+type+'\':
      $(\'#removeProspectReason\').val(\''+reason+'\');'
    message +='$("#removeProspectLogNote").val(\''+type+'\'); $("#include-reason").prop("checked", false);' if createlog
    message +=  'break;'

  message +='
        }
      }
    </script>
  '

  cancelCB = if options.hasOwnProperty('cancelCB') then options['cancelCB'] else undefined

  buttons = [
      {
        label: 'Cancel',
        class: 'btn-cancel'
        callback: cancelCB
      }
    ]
  buttons.push(
      {
        label: "#{@capitaliseFirstLetter(task)}#{if createlog then ', Log' else ''} & Email",
        class: 'btn-email',
        callback: => showReasonCBWithEmailAndLog(fnRmv, true, createlog, cancelCB)
      })
  if createlog
    buttons.push(
        {
          label: "#{@capitaliseFirstLetter(task)} & Log",
          class: 'btn-log-and-email',
          callback: => showReasonCBWithLog(fnRmv, false, createlog, cancelCB)
        })
  buttons.push(
      {
        label: @capitaliseFirstLetter(task),
        class: 'btn-remove',
        callback: => showReasonCB(fnRmv, false, false, cancelCB)
      })

  bootbox.dialog({message: message, buttons: buttons, className: 'bootbox-reason-dialog'})

saveAndCloseInfo = (fnBulk) ->
  params = {}
  params['headquarter'] = $('#hq').val() if $('#hq').length > 0 && $('#hq').val() != ''
  params['missed_interview_date'] = $('#mi').val() if $('#mi').length > 0 && $('#mi').val() != ''
  params['texted_date'] = $('#txt').val() if $('#txt').length > 0 && $('#txt').val() != ''
  params['email_status'] = $('#em').val() if $('#em').length > 0 && $('#em').val() != ''
  params['left_voice_message'] = true if $('#vm').prop("checked") == true
  params['left_voice_message'] = false if $('#vm').prop("checked") == false
  if params['headquarter']
    fnBulk(params)
  else
    bootbox.alert("Sorry, you must enter HQ field")
    undefined

window.bulkEntryForApplicants = (bulk) ->
  message = 'Enter HQ:<br><input id="hq" class="form-control bulk-info" type="text" name="headquarter"><br><br>'
  message += 'Select Missed Interview Date:<br><input id="mi" class="form-control prospect-datepicker bulk-info" type="text" placeholder="DD/MM/YYYY" name="missed_interview_date"><br><br>'
  message += 'Select Texted Date Date:<br><input id="txt" class="form-control prospect-datepicker bulk-info" type="text" placeholder="DD/MM/YYYY" name="texted_date"><br><br>'
  message += 'Select Email Status:<br><select id="em" class=" form-control bulk-info" name="email_status"><option value="" selected="selected"></option><option value="UNCONF">UNCONF</option><option value="HOLDING">HOLDING</option><option value="LIVE &amp; ACTIVE">LIVE &amp; ACTIVE</option><option value="INTERVIEWS">INTERVIEWS</option><option value="EVENT">EVENT</option><option value="REQUEST CALL">REQUEST CALL</option></select><br><br>'
  message += 'Voice Masses: <input id="vm" type="checkbox" name="left_voice_message" class="">'
  message += '<script>
  setUpDatepicker($("input.prospect-datepicker"));
  $("input.prospect-datepicker").watermark("DD/MM/YYYY", {className: "watermark"});
  </script>
  '

  buttons = [
    {
      label: 'Cancel',
      class: 'btn-cancel'
      callback: undefined
    }
  ]
  buttons.push(
    {
      label: "Save & Close",
      class: 'btn-save-and-close',
      callback: => saveAndCloseInfo(bulk)
    })
  bootbox.dialog({message: message, buttons: buttons, className: 'bulk-entry'})

window.checkForLockedEvents = (event_ids, callback) ->
  locked_ids = []
  for id in event_ids
    event = @db.findId('events', id)
    if event.admin_completed && event.date_start > getToday()
      locked_ids.push(id)
  if locked_ids.length == 0
    callback(true)
  else
    message = "Warning:<br>You are either adding or removing a person off an active event.<br>Please confirm all copies will correspond with your actions:"
    for id in locked_ids
      message += "<br>• #{@db.findId('events', id).name}"
    bootbox.confirm(message, callback)

window.getDefaultTaxWeekForEvent = (event) ->
  if event.date_start && event.date_end
    today = getToday()
    date = if today.getTime() < event.date_start.getTime() then event.date_start else if today.getTime() > event.date_end.getTime() then event.date_end else today
    @db.queryAll('tax_weeks', {includes_date: date})[0]
  else
    undefined

window.getCurrentTaxWeek = () ->
  @db.queryAll('tax_weeks', {includes_date: @getToday()})[0]

window.getCountdownString = (targetDate, currentDate) ->
  totalDays = daysBetween(currentDate, targetDate)
  weeks = Math.floor(totalDays/7)
  days = totalDays%7
  return "0" if todalDays <= 0
  return "#{days}d" if weeks == 0
  return "#{weeks}w" if days == 0
  return "#{weeks}w #{days}d"

window.getEventWeekCountdown = (targetDate, currentDate) ->
  totalDays = daysBetween(currentDate, getWeekStart(targetDate))
  return 0 if totalDays <= 0
  return Math.floor((totalDays+6)/7)

window.capitaliseFirstLetter = (string) ->
  string.charAt(0).toUpperCase() + string.slice(1);

window.sentenceCase = (string) ->
  string.replace(/\w\S*/g, (txt) -> return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase())

window.stringToDate = (_date,_format,_delimiter) ->
  formatLowerCase=_format.toLowerCase()
  formatItems=formatLowerCase.split(_delimiter)
  dateItems=_date.split(_delimiter)
  monthIndex=formatItems.indexOf("mm")
  dayIndex=formatItems.indexOf("dd")
  yearIndex=formatItems.indexOf("yyyy")
  month=parseInt(dateItems[monthIndex])
  month-=1
  formatedDate = new Date(dateItems[yearIndex],month,dateItems[dayIndex])
  formatedDate

window.addDays = (startDate, numberOfDays) ->
  returnDate = new Date(
    startDate.getFullYear(),
    startDate.getMonth(),
    startDate.getDate()+numberOfDays,
    startDate.getHours(),
    startDate.getMinutes(),
    startDate.getSeconds())
  returnDate

window.isTomorrow = (reference_date, date) ->
  reference_date? && date? && reference_date.getFullYear() == date.getFullYear() && reference_date.getMonth() == date.getMonth() && reference_date.getDate() == date.getDate() - 1

window.dayOfWeek = (date) ->
  ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][date.getDay()]

window.dayOfWeekClass = (date) ->
  if date? then 'day-of-week-'+dayOfWeek(date).toLowerCase() else ''

window.treatAsUTC = (date) ->
  result = new Date(date);
  result.setMinutes(result.getMinutes() - result.getTimezoneOffset());

window.daysBetween = (startDate, endDate) ->
  millisecondsPerDay = 24 * 60 * 60 * 1000
  (treatAsUTC(endDate) - treatAsUTC(startDate)) / millisecondsPerDay

window.getToday = ->
  date = new Date;
  date.setHours(0,0,0,0)
  date

window.getWeekStart = (date) ->
  day_of_week = date.getDay() # //0-6. 0 is Sunday, 1 is Monday, 6 is Saturday
  day_of_week = 7 if (day_of_week == 0) # Make Sunday 7
  start_date = addDays(date, (day_of_week-1)*-1) #Get Monday of the week

window.removeTags = (html) ->
  white="b|i|p|br";#allowed tags
  black="script|object|embed";#completely removed tags
  e=new RegExp("(<("+black+")[^>]*>.*</\\2>|(?!<[/]?("+white+")(\\s[^<]*>|[/]>|>))<[^<>]*>|(?!<[^<>\\s]+)\\s[^</>]+(?=[/>]))", "gi");
  return html.replace(e,"")

window.replaceOptions = ($object, options) ->
  $object.empty()
  $.each(options, (index, option) ->
    $option = $("<option></option>").attr("value", option.value).text(option.text);
    $object.append($option))

window.getWeekOfYear = (date) ->
  onejan = new Date(date.getFullYear(),0,1);
  return Math.ceil((((date - onejan) / 86400000) + onejan.getDay()+0) / 7);

window.distanceBetweenPointsInMiles = (point1, point2) ->
  [lat1, lng1] = point1
  [lat2, lng2] = point2
  if lat1? and lng1? and lat2? and lng2?
    rad_per_deg = Math.PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters


    dlat_rad = (lat2-lat1) * rad_per_deg  # Delta, converted to rad
    dlng_rad = (lng2-lng1) * rad_per_deg

    lat1_rad = lat1 * rad_per_deg
    lng1_rad = lng1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg
    lng2_rad = lng2 * rad_per_deg

    a = Math.pow(Math.sin(dlat_rad/2), 2) + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.pow(Math.sin(dlng_rad/2), 2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

    d_meters = rm * c # Delta in meters
    d_miles = Math.round(d_meters/1000*0.62137)
  else
    -1

window.selectRecord = (tableName, id) ->
  window.office_selected[tableName] || window.office_selected[tableName] = {}
  window.office_selected[tableName][id] = true

window.deselectRecord = (tableName, id) ->
  window.office_selected[tableName] || window.office_selected[tableName] = {}
  if window.office_selected[tableName][id]
    delete window.office_selected[tableName][id]

window.isSelected = (tableName, id) ->
  window.office_selected[tableName] || window.office_selected[tableName] = {}
  window.office_selected[tableName][id] || false

window.clearAllSelected = (tableName) ->
  window.office_selected[tableName] || window.office_selected[tableName] = {}
  window.office_selected[tableName] = {}

window.nSelected = (tableName) ->
  window.office_selected[tableName] || window.office_selected[tableName] = {}
  Object.keys(window.office_selected[tableName]).length

window.rebind = (elements, type, routine) ->
  elements.unbind(type, routine)
  elements.bind(type, routine)

window.isInt = (value) ->
  !isNaN(value) &&
  parseInt(Number(value)) == value &&
  !isNaN(parseInt(value, 10));

window.matchStringStart = (value, search) ->
  if value && search && search.match(/\S/) # must have at least 1 non-whitespace char
    regex = new RegExp('(^|, )' + search, 'i')
    value.match(regex)

window.date_sort_asc = (date1, date2) ->
  return 1  if (date1 > date2)
  return -1 if (date1 < date2)
  return 0

window.clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime())

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags)

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = @clone obj[key]

  return newInstance

window.min = (a, b) ->
  if a < b then a else b

window.max = (a, b) ->
  if a > b then a else b

window.arrayContainsElementInAnotherArray = (needle, haystack) ->
  for i in [0..needle.length]
    if(haystack.indexOf(needle[i]) > -1)
      return true
  false

window.nCss = (element, prop) ->
  parseInt(element.css(prop), 10)

window.elementHeight = (element) ->
  @nCss(element,'height') + @nCss(element,'padding-top') + @nCss(element,'padding-bottom') + (2*@nCss(element,'border'))

window.getNumRows = (tab) ->
  rl = $("\##{tab} .record-list").not('.slideover .record-list')
  windowHeight = $(window).height()
  viewTabsHeight = @nCss($('#view-tabs'), 'height')
  recordListTop = @nCss(rl, 'top')
  recordListBottomMargin = @nCss(rl, 'bottom')
  headerHeight = @elementHeight(rl.find('.table-th'))
  rowHeight = if (rl.find('.td').length > 0) then @elementHeight(rl.find('.td')) else  @elementHeight($('.record-list .td')) #Because some tables don't populate data right away
  rowAreaHeight = windowHeight-viewTabsHeight-recordListTop-headerHeight-recordListBottomMargin
  if rowHeight < rowAreaHeight then Math.floor(rowAreaHeight/rowHeight) else 1

window.getPayrollHeight = ->
# The native scrolling in the handsontable only works if it's container has absolute values for height and width
# So we need to set the height/width manually so the payroll table matches the window dimensions
  grid = $('.payroll-grid, .timesheet-grid')

  # Ugly hardcoded number '207'. Unfortunately, we can't grab the position until the element is drawn, and it's not drawn till we switch to that tab.
  grid.css('height', $(window).height() - 216 - 10)

window.onResize= ->
  viewManager.sendOnly('planner',    'numRows',        @getNumRows('planner'))
  viewManager.sendOnly('events',     'numRows',        @getNumRows('events'))
  viewManager.sendOnly('gigs',       'numRowsApplied', @getNumRows('gigs'))
  viewManager.sendOnly('gigs',       'numRowsHired',   @getNumRows('gigs'))
  viewManager.sendOnly('team',       'numRows',        @getNumRows('team'))
  viewManager.sendOnly('applicants', 'numRows',        @getNumRows('applicants'))
  viewManager.sendOnly('bulkInterviews', 'numRows',    @getNumRows('bulkInterviews'))
  viewManager.sendOnly('clients',    'numRows',        @getNumRows('clients'))
  viewManager.sendOnly('invoices',   'numRows',        @getNumRows('invoices')) if ($('#invoices').length > 0)
  @getPayrollHeight()

window.setUpDatepicker = (jq, format='dd/mm/yy', defaultmonth=null) ->
  # 'jq' is a jQuery object
  jq.datepicker({
    dateFormat: format,
    defaultDate: defaultmonth,
    onSelect: (dateText, inst) ->
      if dateText != inst.lastVal
        jq.blur()
        jq.datepicker('hide')
        # Normally we detect when the contents of a text input have changed using the 'keyup' event
        # But when it is set by a datepicker 'keyup' never fires -- we'll have to do it manually
        jq.trigger('keyup')
        jq.trigger('change')
  })
  jq.addClass('datepicker-field')
  jq.on('keydown', (e) ->
    keyCode = e.keyCode || e.which;
    if (keyCode == 9)
      jq.datepicker('hide'))

window.enableDatesOnDatePicker = ($date_field, dates) ->
  datesAsGetTime = dates.map((date) => date.getTime())
  $date_field.datepicker('option', 'beforeShowDay', (date) => [($.inArray(date.getTime(), datesAsGetTime) != -1), ""])
  #Set a custom property so that widgets.coffee:TableWidget:draw() knows to refresh the datepicker when changed
  $date_field.attr('enabled-dates', datesAsGetTime.join(','))

window.getDatesFromRange = (date_start, date_end) ->
  dates = []
  `for (d = new Date(date_start); d <= date_end; d.setDate(d.getDate() + 1)) {
    dates.push(new Date(d));
  }`
  dates

window.dateInRange = (date, date_start, date_end) ->
  dateAsGetTime = date.getTime()
  date_start.getTime() <= dateAsGetTime && dateAsGetTime <= date_end.getTime()

window.deepCopy = (obj) ->
  $.extend(true, {}, obj)

window.getDropdownIntVal = ($dropdown) ->
  val = $dropdown.val()
  if (val? && val != '') then parseInt(val, 10) else null

window.getDropdownDateVal = ($dropdown) ->
  val = $dropdown.val()
  if (val? && val != '') then new Date(Date.parse(val)) else null

window.personalPosessive = (gender) ->
  gender == "M" ? "his" : (gender == "F" ? "her" : "their")

# Consider blank if value is:
# - undefined
# - null
# - false
# - string with no characters (other than whitespace)
# - empty array
# - empty object
window.isBlank = (val) ->
  ( val == undefined ||
    val == null ||
    val == false ||
    (typeof(val) == 'string' && !val.replace(/\s/g,'').length) ||
    (Array.isArray(val) && val.length == 0) ||
    (val.constructor == Object && Object.keys(val).length == 0)
  )

window.isPresent = (val) ->
  !isBlank(val)

# SEARCHING DOM

# Find a DOM node by its 'name' (for form inputs) or ID
# Can use on jQuery object OR raw DOM object
$.fn.node = (query) ->
  @get(0).node(query)
Element::node = (query) ->
  @querySelector("[name='#{query}']:not([type='hidden'])") || @querySelector("##{query}")

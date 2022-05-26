# Encapsulates manipulation of a table (adding, removing, reordering, updating rows and cells)
class GridWidget
  constructor: (@viewport, @_columns, @actor) ->
    @viewport = $(@viewport)
    @viewport.empty()
    @viewport.append(
      '<table class="table-widget" style="width:100%" cellspacing="0">
        <tbody>
          <tr class="tr-head"></tr>
        </tbody>
      </table>')

    @_tbody  = @viewport.find('tbody')
    @header  = @viewport.find('tr.tr-head')

    column.type ||= 'string' for column in @_columns

    for column, index in @_columns
      colHtml  = '<td class="table-th'
      colHtml += ' sorthdr' unless column.sortable == false
      colHtml += '"'
      colHtml += ' style="display:none"' if column.hidden
      colHtml += '>' + column.name + '</td>'
      colHead = $(colHtml)
      unless column.sortable == false
        do (index, column) => colHead.click(=>
          @actor.msg('sort', {from: @, index: index, column: column, ascend: if @sortedOn == index then !@sortAscend else true}))
      @header.append(colHead)

    @rows            = []
    @_selectedRow    = null
    @_selectedIndex  = null # 0-based
    @sortedOn        = null # column index
    @sortAscend      = true
    @cellContentChangedCallbacks = []

  cssClass: (cls) ->
    @viewport.find('table').addClass(cls)
  cssStyle: (style) ->
    @viewport.find('table').attr('style', style)
  columns:       -> @_columns
  selectedRow:   -> @_selectedRow
  selectedIndex: -> @_selectedIndex
  tbody:         -> @_tbody
  tableViewport: -> @viewport
  allRows:       -> @rows

  addCellContentChangedCallback: (callback) ->
    @cellContentChangedCallbacks.push(callback)

  clearRows: ->
    @_tbody.find('tr:not(:first-child)').remove()
    @rows = []
    @deselectRow()
  newRow: (index) ->
    row   = '<tr class="body-row tr-'
    row  += (if (index % 2) == 0 then 'even' else 'odd')
    row  += ' tr-sel' if @_selectedIndex == index
    row  += '">'
    for column in @_columns
      row += '<td class="td td-' + column.type
      row += '"'
      row += ' style="display:none"' if column.hidden
      row += '></td>'
    row  += '</tr>'
    row   = $(row)
    row.hover((-> $(this).addClass('tr-over')), (-> $(this).removeClass('tr-over')))
    row.attr('data-index', index)
    row
  appendRow: (cellContents) ->
    index = @rows.length
    row = @newRow(index)
    @rows.push(row)
    @_tbody.append(row)
    @updateRow(index, cellContents)
    row
  insertRow: (rowIndex, cellContents) ->
    if rowIndex < 0 || rowIndex > @rows.length
      throw new Error("Can't insert row at position " + rowIndex + " (only have " + @rows.length + ")")
    if @_selectedIndex? && @_selectedIndex >= rowIndex
      @_selectedIndex += 1
    row = @newRow(rowIndex)
    @rows.splice(rowIndex, 0, row)
    @_tbody.find('tr:nth-child('+(rowIndex+1)+')').after(row) # this works because we have a header row
    @updateRow(rowIndex, cellContents)
    @resetRowIndexes()
    row
  moveRow: (fromIndex, toIndex) ->
    return if fromIndex == toIndex
    if fromIndex < 0 || fromIndex >= @rows.length
      throw new Error("Can't move row at position " + fromIndex + " (only have " + @rows.length + ")")
    if toIndex < 0 || toIndex >= @rows.length
      throw new Error("Can't move row to position " + toIndex + " (only have " + @rows.length + ")")
    row = @rows[fromIndex]
    row.detach()
    @_tbody.find('tr:nth-child('+(toIndex+1)+')').after(row) # this works because we have a header row
    @rows.splice(fromIndex, 1)
    @rows.splice(toIndex, 0, row)
    if @_selectedIndex?
      if @_selectedIndex == fromIndex
        @_selectedIndex = toIndex
      else if fromIndex > toIndex && @_selectedIndex >= toIndex && @_selectedIndex < fromIndex
        @_selectedIndex += 1
      else if fromIndex < toIndex && @_selectedIndex <= toIndex && @_selectedIndex > fromIndex
        @_selectedIndex -= 1
    @resetRowIndexes()
    row
  updateRow: (rowIndex, cellContents) ->
    if rowIndex < 0 || rowIndex >= @rows.length
      throw new Error("Can't update row with index " + rowIndex + " (only have " + @rows.length + ")")
    row = @rows[rowIndex]
    that = @
    row.find('td').each((i, td) ->
      if cellContents.length > i
        $td = $(td)
        if $.isArray(cellContents[i])
          $td.html(cellContents[i][0])
          cellContents[i][1]($(td))
        else
          $td.html(cellContents[i])
        callback($td) for callback in that.cellContentChangedCallbacks
    )
  updateCell: (rowIndex, colIndex, content) ->
    if rowIndex < 0 || rowIndex >= @rows.length || colIndex < 0 || colIndex >= @_columns.length
      throw new Error("Can't update cell " + rowIndex + "," + colIndex " (only have " + @rows.length + " rows and " + @_columns.length + " columns)")
    row = @rows[rowIndex]
    $td = row.find('td:nth-child('+(colIndex+1)+')')
    $td.html(content.html)
    content.fn($td) if content.fn
    callback($td) for callback in @cellContentChangedCallbacks

  removeRow: (rowIndex) ->
    if rowIndex < 0 || rowIndex >= @rows.length
      throw new Error("Can't remove row with index " + rowIndex + " (only have " + @rows.length + ")")
    @rows[rowIndex].remove()
    @rows.splice(rowIndex, 1)
    if @_selectedIndex == rowIndex
      @deselectRow()
    else if @_selectedIndex > rowIndex
      @_selectedIndex -= 1
    @resetRowIndexes()
  truncateRows: (nRows) ->
    if nRows < 0
      throw new Error("Can't truncate number of rows to " + nRows)
    return if nRows >= @rows.length
    for row in @rows.slice(nRows, @rows.length)
      row.remove()
    @rows.length = nRows
    if @_selectedIndex? && @_selectedIndex >= nRows
      @deselectRow()
  resetRowIndexes: ->
    for row, index in @rows
      row.attr('data-index', index)

  selectRow: (index) =>
    if index < 0 || index >= @rows.length
      throw new Error("Can't select row with index " + index + " (only have " + @rows.length + ")")
    if @_selectedRow?
      @_selectedRow.removeClass('tr-sel')
    @_selectedRow    = @rows[index]
    @_selectedIndex  = index
    @_selectedRow.addClass('tr-sel')

  deselectRow: ->
    if @_selectedRow?
      @_selectedRow.removeClass('tr-sel')
    @_selectedRow = @_selectedIndex = null
    @actor.msg('deselect')

  sortedOnColumn: (index, ascend) ->
    @header.find('span.sortind').remove()

    @sortedOn   = index
    @sortAscend = ascend

    headerCell = $(@header.find('td')[@sortedOn])
    if @sortAscend
      headerCell.append("<span class='sortind'>\u25BC</span>")
    else
      headerCell.append("<span class='sortind'>\u25B4</span>")

# Like GridWidget, but interface is in terms of records rather than rows and cells
# Do *not* directly manipulate the HTML table or GridWidget which TableWidget uses to render itself
# It should only be updated by TableWidget in response to receiving new data

# Column Setup Notes:
# virtual:      undefined (default): indicates that the column comes directly from a record column
#               true:                indicates that the column does NOT come directly from a record column (ie. it is calculated from records or something else)
# id:           undefined (default): the table will never update this column
#               string:              name of record column (if virtual is NOT true), otherwise NOT the name of a record column (if virtual IS true)
# type:         string (default), number, date, boolean : formats the column data
# changes_with: undefined (default):   column will only change if own data has changed
#               string:                column will only change if the specified column.id has changed
#               [string1, string2...]: column will only change if one or more of the specified column.id has changed (can include own column.id)
#                                      This is useful if this columns properties change (ie. class, format, etc) based on another
#                                      column changed, even if the columns own record column data hasn't changed
class TableWidget
  constructor: (@viewport, @_columns, @actor, @options = {}) ->
    @grid = new GridWidget(@viewport, @_columns, @actor)
    delegate(@, @grid, 'cssClass', 'cssStyle', 'columns', 'selectedRow', 'selectedIndex', 'sortedOnColumn', 'tbody', 'tableViewport', 'allRows',
      'addCellContentChangedCallback')

    @_columnIndexForId = {}
    for column, index in @_columns
      @_columnIndexForId[column.id] = index
    # 'rowBuilder' is a function -- it takes the object for a row, and returns an Array of HTML fragments/jQuery DOM objects
    @_rowBuilder = (record) =>
      (for column in @_columns
        value = record[column.id]
        value? && switch column.type
          when 'string', 'number'
            escapeHTML(value.toString())
          when 'date'
            printDate(value)
          when 'boolean'
            if value then "\u2714" else "\u2718"
          else
            throw new Error("Unknown column type: " + column.type)
      )
    @_rowStyler = (tr, i) =>
      $tr = $(tr)
      cssClass = if (i % 2) == 0 then 'tr-even' else 'tr-odd'
      if cssClass == 'tr-even'
        if $tr.hasClass('tr-odd')
          $tr.removeClass('tr-odd')
          $tr.addClass('tr-even')
      else
        if $tr.hasClass('tr-even')
          $tr.removeClass('tr-even')
          $tr.addClass('tr-odd')

    @_records = []
    @_drawnValues = {} # {record ID: [values which were used to render each cell]} -- used to tell when a cell needs to be re-rendered
    @_selectedRecord = null
    @numBlanks = 0 # Number of rows (presumably editable) at the end which do not have a corresponding record

    # It would make sense to put this in GridWidget -- but it is here so we can include the newly selected record in the message data
    # Note we do NOT directly change the selected row -- an arrow key press is a REQUEST to select a different row, but the actor
    #   receiving the message decides what to do about that request
    @viewport.on('keydown', (e) =>
      switch e.which
        when 38 # "up" arrow key
          if @selectedIndex()? && @selectedIndex() > 0
            @actor.msg('select', {from: @, index: @selectedIndex() - 1, record: @_records[@selectedIndex() - 1]})
            false
        when 40 # "down" arrow key
          if @selectedIndex()? && @selectedIndex() < (@grid.rows.length-1)
            @actor.msg('select', {from: @, index: @selectedIndex() + 1, record: @_records[@selectedIndex() + 1]})
            false
    )

  rowBuilder: (@_rowBuilder) ->
  rowStyler: (@_rowStyler) ->
  selectedRecord: -> @_selectedRecord
  records: -> @_records
  blankRecord: (@_blankRecord) ->
  blankRows: (numBlanks) ->
    if numBlanks > @numBlanks
      for _ in [0...(numBlanks - @numBlanks)]
        newRow = @grid.appendRow(@_rowBuilder(@_blankRecord))
        @setupEventHandlers(newRow)
    else if numBlanks < @numBlanks
      @grid.truncateRows(@_records.length + numBlanks)
    @numBlanks = numBlanks

  selectRow: (index) ->
    @grid.selectRow(index)
    @_selectedRecord = @_records[index]

  getRecordFromRow: (row) ->
    @_records[parseInt(row.attr('data-index'), 10)]

  deselectRow: ->
    @grid.deselectRow()
    @_selectedRecord = null

  draw: (records) ->
    # avoid redrawing rows unnecessarily -- this isn't just for efficiency, but because a custom row-building function
    #   may put user-editable controls in rows which we don't want to unnecessarily overwrite
    existing    = {} # {record ID: index of row in table}
    drawnValues = {} # {record ID: [values which were used to render each cell]}

    if sample = records[0]
      for column in @_columns
        if column.id
          if column.virtual && (column.id of sample)
            throw "Cannot specify a virtual column with the same name as record column #{column.id}"
          if !(column.virtual) && !(column.id of sample)
            throw "Column #{column.id} does not exist in record. Did you mean set { virtual: true } on it ?"
          if column.changes_with
            for id in [].concat(column.changes_with)
              throw "Column #{column.id} changes_with '#{id}' does not exist" unless @_columnIndexForId[column.id]

    for record, index in @_records
      existing[record.id] = index

    for record, index in records
      # is this record already displayed in the table?
      if (existingIndex = existing[record.id])?
        # if so, use the existing row, and only update cells for which the record attribute identified by column.id has changed
        contents = @_rowBuilder(record)
        for column, colIndex in @_columns
          content = @getCellHtmlAndFn(contents[colIndex])

          toCompare = if (column.changes_with? || column.id?) then [].concat(column.changes_with || column.id) else []
          newValues = toCompare.map((colId) =>
            if colId of record
              record[colId]
            else
              ##### This is a virtual column, so pull the value directly from the data to be rendered
              @getCellValue(@getCellHtmlAndFn(contents[@_columnIndexForId[colId]]).html)
          )

          ##### drawnValues contains values from records AND virtual records
          oldValues = toCompare.map((colId) => @_drawnValues[record.id][colId])

          if !_.isEqual(oldValues, newValues)
            @grid.updateCell(existingIndex, colIndex, content)
          else
            $td = @grid.rows[existingIndex].find('td:nth-child('+(colIndex+1)+')')
            # Update a dropdown if the options have changed
            elements = $td.find('select')
            if elements.length > 0
              throw 'Cannot have more than one select element in a cell' if elements.length > 1
              element = elements.first()
              # If it's an array, the first element is the html column, and the 2nd element is a function to be executed
              newOptionVals = $.map($($.parseHTML(content.html)).find('option'), (option) -> $(option).val()).join()
              oldOptionVals = $.map(element.find('option'), (option) -> $(option).val()).join()
              newOptionTexts = $.map($($.parseHTML(content.html)).find('option'), (option) -> $(option).text()).join()
              oldOptionTexts = $.map(element.find('option'), (option) -> $(option).text()).join()

              if (newOptionVals != oldOptionVals) || (newOptionTexts != oldOptionTexts)
                @grid.updateCell(existingIndex, colIndex, content)

            # Update datePicker if:
            # enabled-dates (custom property) has changed OR
            # start/end changed and value is not out of range
            elements = $td.find('.datepicker-field')
            if elements.length > 0
              throw 'Cannot have more than one datepicker in a cell' if elements.length > 1
              element = elements.first()
              $content = $($.parseHTML(content.html))
              # enabled-dates is a custom attribute used to indicate which dates are selectable in the datepicker
              # This will be set by enableDatesOnDatePicker()
              if $content.attr('enabled-dates') != element.attr('enabled-dates')
                @grid.updateCell(existingIndex, colIndex, content)
              else
                # Stupid Datepicker sets start/endDate in Local time, and gets in UTC time
                newStartDate = utcToLocal(new Date(content.html.datepicker('option', 'minDate')))
                oldStartDate = utcToLocal(new Date(element.datepicker('option', 'minDate')))
                newEndDate = utcToLocal(new Date(content.html.datepicker('option', 'maxDate')))
                oldEndDate = utcToLocal(new Date(element.datepicker('option', 'maxDate')))
                newDate = $(content.html).val()
                if (newStartDate != oldStartDate) || (newEndDate != oldEndDate)
                  element.datepicker('option', 'minDate', newStartDate) if newDate >= newStartDate
                  element.datepicker('option', 'maxDate', newEndDate)   if newDate <= newEndDate

        # fix up the table display AND the data which we will use to handle the following rows
        @grid.moveRow(existingIndex, index)
        existing[record.id] = index
        if existingIndex > index
          for id,idx of existing when idx >= index && idx < existingIndex
            existing[id] = idx+1
        else if existingIndex < index
          for id,idx of existing when idx <= index && idx > existingIndex
            existing[id] = idx-1

        # if this record was selected, update @_selectedRecord to point to the UPDATED record, not the old one
        if @_selectedRecord? && record.id == @_selectedRecord.id
          @_selectedRecord = record
      else
        newRow = @grid.insertRow(index, @_rowBuilder(record))
        @setupEventHandlers(newRow)
        for id,idx of existing when idx >= index
          existing[id] = idx+1

      drawnValues[record.id] = {}
      for column in @_columns
        if column.id
          if column.id of record
            drawnValues[record.id][column.id] = record[column.id]
          else
            ##### This is a virtual column, so pull data directly from the table
            drawnValues[record.id][column.id] = @getCellValue(@grid.rows[index].find('td:nth-child('+(@_columnIndexForId[column.id]+1)+')').html())

    for toRemove in [(@grid.rows.length - @numBlanks - 1)...(records.length - 1)]
      if toRemove == @selectedIndex()
        @deselectRow()
      @grid.removeRow(toRemove)

    for row, i in @grid.rows
      @_rowStyler(row, i)

    @_records = records
    # Deep Copy
    @_drawnValues = deepCopy(drawnValues)

    @actor.msg('drew', {from: @})

  getCellHtmlAndFn: (content) ->
    if $.isArray(content) then {html: content[0], fn: content[1]} else {html: content}

  getCellValue: (content) ->
    if html = $.parseHTML(content)
      $node = $(html)
      switch $node.get(0).nodeType
        when 1 # Element
          # We normally don't allow more than one element in a cell
          if $node.length > 1
            # But, we make an exception for a single select2 element, which generates a select and a span
            if $node.length == 2 && $node.hasClass('select2')
              $node = $node.filter('select')
            else
              throw "Can't have more than one element in a cell"
          switch $node.get(0).tagName
            when 'SELECT', 'TEXTAREA'
              $node.val()
            when 'INPUT'
              switch $node.attr('type')
                when 'checkbox'
                  $node.is(':checked')
                else
                  $node.val()
            when 'SPAN'
              $node.text()
            else
              throw "Unexpected tag name: #{$node.get(0).tagName}"
        when 3 #Text
          $node.text()
        else
          throw "Unknown nodeType: #{html.nodeType}"
    else
      content
    
  setupEventHandlers: (row) ->
    row.click(=>
      i = parseInt(row.attr('data-index'),10)
      if i != @selectedIndex()
        @actor.msg('select', {from: @, index: i, record: @_records[i]}); true)
    row.dblclick(=>
      i = parseInt(row.attr('data-index'),10)
      @actor.msg('activate', {from: @, index: i, record: @_records[i]}))

  addRow: (record) ->
    @numBlanks += 1
    newRow = @grid.appendRow(@_rowBuilder(record))
    @setupEventHandlers(newRow)
    newRow.addClass('blank')
    newRow

  addBlank: ->
    @numBlanks += 1
    newRow = @grid.appendRow(@_rowBuilder(@_blankRecord))
    @setupEventHandlers(newRow)
    newRow.addClass('blank')
    newRow

  removeBlank: (index) ->
    if index < @_records.length
      throw new Error("That index is not a blank row")
    else if index >= @_records.length+@numBlanks
      throw new Error("That index is past the last blank row")
    @numBlanks -= 1
    if index == @selectedIndex()
      @deselectRow()
    @grid.removeRow(index)

  removeAllBlanks: () ->
    return if @numBlanks == 0
    if @selectedIndex()? && @selectedIndex >= @_records.length
      @deselectRow()
    @grid.truncateRows(@_records.length)
    @numBlanks = 0

  refreshBlanks: (numBlanks=@numBlanks) ->
    @removeAllBlanks()
    for _ in [1..numBlanks]
      @addBlank()


class EditableTable
  constructor: (@table, @actor) ->
    delegate(@, @table, 'selectRow', 'deselectRow', 'rowStyler', 'rowBuilder', 'cssClass', 'cssStyle', 'allRows', 'draw',
      'selectedRecord', 'selectedRow', 'columns', 'sortedOnColumn', 'tbody', 'tableViewport', 'refreshBlanks', 'getRecordFromRow')

    # If user starts editing a row, select it
    @table.viewport.on('focus', 'input,select,textarea', (event) =>
      index = parseInt($(event.target).closest('tr').attr('data-index'), 10)
      if index && index != @table.selectedIndex()
        @actor.msg('select', {from: @, index: index, record: @table.records()[index]})
      if @table.numBlanks > 0 && index == (@table.records().length + @table.numBlanks - 1)
        # it's the last blank row
        @table.addBlank())
    # When enter is pressed, save the current row
    @table.viewport.on('keypress', (event) =>
      if event.which == 13 && row = @table.selectedRow()
        event.preventDefault()
        @actor.msg('save', {from: @, record: @table.selectedRecord(), row: row, index: @table.selectedIndex()}))

    @watcher = new FormChangeWatcher(@table.tbody(), @actor)
    delegate(@, @watcher, 'isDirty', 'isAreaDirty', 'markClean', 'markAreaClean')
    @table.addCellContentChangedCallback((cell) => @watcher.recordOriginalValues(cell))

  displayBlankRow: (blankRecord) ->
    @table.blankRecord(blankRecord)
    if @table.numBlanks == 0
      @table.addBlank()

  rowWasSaved: (index) ->
    if index >= @table.records().length
      @table.removeBlank(index)
      if @table.numBlanks == 0
        @table.addBlank()

  revert: ->
    @table.viewport.find('.erroneous-row').removeClass('erroneous-row')
    @watcher.revert()

#This is like the EditableTable, except there is no automatic addition of blank rows
# addRow needs to be called manually
class EditableStaticTable
  constructor: (@table, @actor, @options={}) ->
    delegate(@, @table, 'selectRow', 'deselectRow', 'rowStyler', 'rowBuilder', 'cssClass', 'cssStyle', 'allRows', 'addCellContentChangedCallback'
      'selectedRecord', 'selectedRow', 'columns', 'sortedOnColumn', 'tbody', 'tableViewport',
      'getRecordFromRow', 'draw', 'addRow', 'removeBlank')

    # If user starts editing a row, select it
    @table.viewport.on('focus', 'input,select,textarea', (event) =>
      index = parseInt($(event.target).closest('tr').attr('data-index'), 10)
      if index && index != @table.selectedIndex()
        @actor.msg('select', {from: @, index: index, record: @table.records()[index]}))

    # Save a row immediately if saveOnChange option is enabled
    if @options.saveOnChange
      @table.viewport.on('change', 'select:not(.never-dirty, .select2-hidden-accessible),input:not(.never-dirty)', (event) =>
        if row = @table.selectedRow()
          @actor.msg('save', {from: @, record: @table.selectedRecord(), row: row, index: @table.selectedIndex()}))
      @table.viewport.on('select2:close', 'select.select2-hidden-accessible:not(.never-dirty)', (event) =>
        if row = @table.selectedRow()
          @actor.msg('save', {from: @, record: @table.selectedRecord(), row: row, index: @table.selectedIndex()}))

    # When enter is pressed, save the current row
    @table.viewport.on('keypress', (event) =>
      if event.which == 13 && row = @table.selectedRow()
        event.preventDefault()
        @saveCurrentRow())

    @watcher = new FormChangeWatcher(@table.tbody(), @actor)
    delegate(@, @watcher, 'isDirty', 'isAreaDirty', 'markClean', 'markAreaClean')
    @table.addCellContentChangedCallback((cell) => @watcher.recordOriginalValues(cell))

  saveCurrentRow: ->
    if row = @table.selectedRow()
      @actor.msg('save', {from: @, record: @table.selectedRecord(), row: row, index: @table.selectedIndex()})

  rowWasSaved: (index) ->
    if $(@table.allRows()[index]).is('.blank')
      @table.removeBlank(index)

  revert: ->
    @table.viewport.find('.erroneous-row').removeClass('erroneous-row')
    @watcher.revert()

  refreshBlanks: (numBlanks=@numBlanks) ->
    # refreshBlanks is supposed to wipe out all the 'blank rows' and recreate them
    # but with EditableStaticTable, each 'blank row' is unique and can't just be
    #   regenerated from a common template
    unless numBlanks == 0
      throw new Error("Can't refresh blanks on EditableStaticTable")
    @table.removeAllBlanks()

class QueryTable
  constructor: (@widget, @db, @tableName, @sorter) ->
    delegate(@, @widget, 'selectRow', 'deselectRow', 'rowStyler', 'rowBuilder', 'cssClass', 'cssStyle',
      'selectedRecord', 'revert', 'isDirty', 'markClean', 'markAreaClean', 'selectedRow', 'addRow', 'removeBlank'
      'displayBlankRow', 'isAreaDirty', 'rowWasSaved', 'tbody', 'tableViewport', 'refreshBlanks', 'allRows', 'saveCurrentRow', 'getRecordFromRow')

    @filters = {}
    @searchTerm = null
    @sortColumn = @widget.columns().findItem((col) -> col.name == 'id') unless @sorter
    @sortAscend = true
    @offset = 0
    @limit  = 1000
    @n_records = 0

  setFilters: (filters) ->
    @searchTerm = filters.search
    @filters = deepCopy(filters) # copy
    delete @filters.search

  sortOnColumn: (@sortColumn, @sortAscend=true) ->
    if typeof(@sortColumn) == 'string'
      @sortColumn = @widget.columns().findItem((col) => col.id == @sortColumn)
    index = @widget.columns().findIndex((col) => col.id == @sortColumn.id)
    @widget.sortedOnColumn(index, @sortAscend)
  sortForQuery: ->
    (@sortColumn? && (@sortColumn.sort_by || @sortColumn.id)) || @sorter
  setOffset: (@offset) ->
  setLimit: (@limit) ->

  draw: ->
    [records, @n_records] = @db.query(@tableName, @filters, @sortForQuery(), @sortAscend, @searchTerm, @offset, @limit)
    @widget.draw(records)

  totalRecords: -> @n_records
  allRecords: ->
    @db.queryAll(@tableName, @filters, @sortForQuery(), @sortAscend, @searchTerm)
  indexOfRecord: (record) ->
    # get index of record within WHOLE record set, disregarding offset/limit
    @db.indexOf(@tableName, @filters, @sortForQuery(), @sortAscend, @searchTerm, record.id)


TotalRowDisplay = (queryTable, displayArea) ->
  chain(queryTable, 'draw', ->
    displayArea.html('Records: ' + @totalRecords()))
  queryTable


class TableWithPagination
  constructor: (@queryTable, @pagination) ->
    delegate(@, @queryTable, 'setFilters', 'sortOnColumn', 'setOffset', 'tableViewport', 'allRows',
      'selectRow', 'deselectRow', 'totalRecords', 'allRecords', 'indexOfRecord', 'refreshBlanks',
      'rowStyler', 'rowBuilder', 'cssClass', 'cssStyle', 'selectedRecord', 'revert', 'isDirty', 'tbody',
      'isAreaDirty', 'markClean', 'markAreaClean', 'selectedRow', 'displayBlankRow', 'rowWasSaved', 'saveCurrentRow', 'getRecordFromRow')
    delegate(@, @pagination, 'setPage', 'nextPage', 'prevPage')
    @_pageSize = 20
    @queryTable.setLimit(@_pageSize)
    @queryTable.tableViewport().on('keydown', (e) =>
      switch e.which
        when 33 # page up
          @pagination.prevPage()
          false
        when 34 # page down
          @pagination.nextPage()
          false
    )

  draw: ->
    @queryTable.draw()
    @pagination.setPages(Math.max(1, Math.ceil(@queryTable.totalRecords() / @_pageSize)))
    @pagination.draw()

  pageSize: (size) ->
    if size?
      @queryTable.setLimit(size)
      @_pageSize = size
    else
      @_pageSize

  selectRecord: (record) ->
    index = @queryTable.indexOfRecord(record)
    page = Math.floor(index / @_pageSize)+1
    @queryTable.setOffset((page-1) * @_pageSize)
    @queryTable.draw()
    @queryTable.selectRow(index % @_pageSize)
    if @pagination.currentPage != page
      @pagination.setPage(page)
      @pagination.draw()


class PaginationControls
  constructor: (@viewport, @actor) ->
    @currentPage = 1
    @pages = 1

  setPages: (@pages) ->
    @currentPage = @pages if @currentPage > @pages
  setPage: (@currentPage) ->
    @currentPage = @pages if @currentPage > @pages
    @currentPage = 1      if @currentPage <= 0

  draw: ->
    @viewport.empty()
    @viewport.append($("<a class='first-page' href='#first-page'>First</a>").click(=>
        @firstPage()))
    @viewport.append(' ')
    @viewport.append($("<a class='prev-page' href='#prev-page'>Previous</a>").click(=>
        @prevPage()))
    @viewport.append(" | Page <input class='page-selector' size='2' value='" + @currentPage + "'> of " + @pages + " | ")
    @viewport.append($("<a class='next-page' href='#next-page'>Next</a>").click(=>
      @nextPage()))
    @viewport.append(' ')
    @viewport.append($("<a class='last-page' href='#last-page'>Last</a>").click(=>
      @lastPage()))

    if @currentPage == 1
      disableLink(@viewport.find('.first-page, .prev-page'))
    if @currentPage == @pages
      disableLink(@viewport.find('.next-page, .last-page'))

    pageSelector = @viewport.find('.page-selector')
    pageSelector.change(=>
      page = parseInt(pageSelector.val(), 10)
      if page > 0 && page <= @pages
        @changePage(page)
      else
        # if an invalid page number is entered, revert to the current page number
        pageSelector.val(@currentPage))

  prevPage: ->
    if @currentPage > 1
      @changePage(@currentPage - 1)
  nextPage: ->
    if @currentPage < @pages
      @changePage(@currentPage + 1)
  firstPage: ->
    @changePage(1)
  lastPage: ->
    @changePage(@pages)
  changePage: (page) ->
    if page != @currentPage && page > 0 && page <= @pages
      @actor.msg('page', {from: @, page: page})


class ListView
  constructor: (@db, @viewport, @tableName, @columns, @handler) ->
    @handler ||= new DefaultListViewHandler(@)

    @table = new TableWidget(@viewport.find('.record-list'), @columns, @handler)
    @table = new QueryTable(@table, @db, @tableName)

    totalArea = @viewport.find('.total-records')
    unless totalArea.length == 0
      @table = new TotalRowDisplay(@table, totalArea)

    pagingControls = @viewport.find('.pagination-controls')
    unless pagingControls.length == 0
      @pagination = new PaginationControls(pagingControls, @handler)
      @table = new TableWithPagination(@table, @pagination)

    delegate(@, @table, 'draw', 'setFilters', 'sortOnColumn', 'selectedRecord',
      'rowStyler', 'rowBuilder', 'selectRecord', 'pageSize', 'selectRow', 'setPage', 'setOffset',
      'deselectRow', 'allRecords', 'nextPage', 'prevPage', 'saveCurrentRow', 'getRecordFromRow', 'totalRecords')
    delegate(@, @handler, 'filter')

class DefaultListViewHandler
  constructor: (@view) ->
    Actor(@)
  select: (data) ->
    @view.selectRow(data.index)
  activate: (data) ->
    @view.selectRow(data.index)
  sort: (data) ->
    @view.setPage(1) if @view.setPage? # might not be paginated
    @view.setOffset(0)
    @view.deselectRow()
    @view.sortOnColumn(data.column, data.ascend)
    @view.draw()
  page: (data) ->
    @view.setPage(data.page)
    @view.setOffset((data.page-1) * @view.pageSize())
    @view.deselectRow()
    @view.draw()
  filter: (data) ->
    @view.setFilters(data.filters)
    @view.deselectRow()
    @view.draw()

class EditableListView
  constructor: (@db, @viewport, @tableName, @columns, @formBuilder, @handler, @sorter, @options = {}) ->
    @handler = new DefaultEditableListViewHandler(@, @handler, 1)

    @table = new TableWidget(@viewport.find('.record-list'), @columns, @handler)
    @table.rowBuilder(@formBuilder)
    @table.rowStyler(@options.rowStyler) if @options.rowStyler
    @table = new EditableTable(@table, @handler)
    @table = new QueryTable(@table, @db, @tableName, @sorter)

    totalArea = @viewport.find('.total-records')
    unless totalArea.length == 0
      @table = new TotalRowDisplay(@table, totalArea)

    pagingControls = @viewport.find('.pagination-controls')
    unless pagingControls.length == 0
      @pagination = new PaginationControls(pagingControls, @handler)
      @table = new TableWithPagination(@table, @pagination)

    delegate(@, @table, 'draw', 'setFilters', 'sortOnColumn', 'selectedRecord',
      'rowBuilder', 'selectRecord', 'pageSize', 'selectRow', 'setPage', 'setOffset',
      'deselectRow', 'allRecords', 'markAreaClean', 'revert', 'displayBlankRow',
      'isDirty', 'isAreaDirty', 'selectedRow', 'markClean', 'rowWasSaved', 'tbody',
      'nextPage', 'prevPage', 'refreshBlanks', 'allRows', 'getRecordFromRow')
    delegate(@, @handler, 'filter')

  save: (actor) ->
    @handler.ensureAllSaved(-> actor.msg('saved'))

class EditableStaticListView
  constructor: (@db, @viewport, @tableName, @columns, @formBuilder, @handler, @options = {}) ->
    @handler = new DefaultEditableListViewHandler(@, @handler, 0)

    @table = new TableWidget(@viewport.find('.record-list'), @columns, @handler)
    @table.rowBuilder(@formBuilder)
    @table.rowStyler(@options.rowStyler) if @options.rowStyler
    @table = new EditableStaticTable(@table, @handler, @options)
    @table = new QueryTable(@table, @db, @tableName)

    totalArea = @viewport.find('.total-records')
    unless totalArea.length == 0
      @table = new TotalRowDisplay(@table, totalArea)

    pagingControls = @viewport.find('.pagination-controls')
    unless pagingControls.length == 0
      @pagination = new PaginationControls(pagingControls, @handler)
      @table = new TableWithPagination(@table, @pagination)

    delegate(@, @table, 'draw', 'setFilters', 'sortOnColumn', 'selectedRecord',
      'rowBuilder', 'selectRecord', 'pageSize', 'selectRow', 'setPage', 'setOffset',
      'deselectRow', 'allRecords', 'markAreaClean', 'revert', 'addRow', 'removeBlank',
      'isDirty', 'isAreaDirty', 'selectedRow', 'markClean', 'rowWasSaved', 'tbody',
      'nextPage', 'prevPage', 'refreshBlanks', 'saveCurrentRow', 'allRows', 'getRecordFromRow')
    delegate(@, @handler, 'filter')

  save: (actor) ->
    @handler.ensureAllSaved(-> actor.msg('saved'))

class DefaultEditableListViewHandler
  constructor: (@view, @parent, @numBlanks) ->
    Actor(@)
    @activeRequests = {}
    @pendingCallbacks = [] # will be called if all pending saves complete successfully
  select: (data) ->
    @saveCurrentRow()
    @view.selectRow(data.index)
    @parent.msg('select', data)
  deselect: ->
    @parent.msg('deselect')
  activate: (data) ->
    @saveCurrentRow()
    @view.selectRow(data.index)
    @parent.msg('activate', data)
  drew: ->
    @parent.msg('drew')
  sort: (data) ->
    @ensureAllSaved(=>
      @view.setPage(1) if @view.setPage
      @view.setOffset(0)
      @view.deselectRow()
      @view.sortOnColumn(data.column, data.ascend)
      @view.draw()
      @parent.msg('deselected', data))
  page: (data) ->
    @ensureAllSaved(=>
      @view.setPage(data.page)
      @view.setOffset((data.page-1) * @view.pageSize())
      @view.deselectRow()
      @view.draw()
      @parent.msg('deselected', data)
      @parent.msg('page', data))
  filter: (data) ->
    @ensureAllSaved(=>
      @view.setFilters(data.filters)
      # wipe out blank rows -- this is because the list view might be editable, for
      #   something like Locations which are linked to Events, and we may have just
      #   moved to showing Locations for a *different* Event
      @view.deselectRow()
      @view.draw()
      @view.refreshBlanks(@numBlanks)
      @parent.msg('deselected', data))
  hide: (data) ->
    @ensureAllSaved(=>
      data.actor.msg('hidden', {from: @}) if data.actor?)
  save: (data) ->
    # called when user presses <enter> in table
    @saveCurrentRow()
  clean: (data) ->
    @updateDirtyHighlight()
    @parent.msg('clean', data)
  dirty: (data) ->
    @updateDirtyHighlight()
    @parent.msg('dirty', data)
  updateDirtyHighlight: ->
    @view.tbody().find('tr:not(.tr-head)').each((i,tr) =>
      tr = $(tr)
      if @view.isAreaDirty(tr)
        tr.addClass('dirty-row')
      else
        tr.removeClass('dirty-row'))

  saveCurrentRow: ->
    @saveRow(@view.selectedRow())

  saveRow: (row) ->
    if row && @view.isAreaDirty(row)
      uniqueId = Math.random().toString(36)
      @activeRequests[uniqueId] = true
      @parent.msg('save', {
        from: @,
        record: @view.getRecordFromRow(row)
        row: row,
        data: row.find('input,select,textarea').serialize(),
        actor: Actor(
          saved: =>
            @view.markAreaClean(row)
            @updateDirtyHighlight()
            row.removeClass('erroneous-row')
            @view.rowWasSaved(parseInt(row.attr('data-index'), 10))
            delete @activeRequests[uniqueId]
            if Object.keys(@activeRequests).length == 0
              callback() for callback in @pendingCallbacks
              @pendingCallbacks = []
          notsaved: =>
            row.addClass('erroneous-row')
            delete @activeRequests[uniqueId]
            @pendingCallbacks = [])})

  ensureAllSaved: (callback) ->
    if @view.isDirty()
      rowSaving = false
      # is current row being saved right now? does it need to?
      for row in @view.allRows()
        if @view.isAreaDirty(row)
          if !@activeRequests[row.attr('data-index')]?
            # current row has been changed but isn't saved yet; save it first
            rowSaving = true
            @pendingCallbacks.push(callback)
            @saveRow(row)
      unless rowSaving
        if Object.keys(@activeRequests).length == 0
          # nothing is being saved right now
          callback()
        else
          # something is being saved right now, wait for it
          @pendingCallbacks.push(callback)
    else
      callback()

class FilterBar
  constructor: (@viewport, @actor) ->
    filtersChanged = =>
      @actor.msg('beforeFilter', {from: @}, {synchronous: true})
      @actor.msg('filter', {from: @, filters: @selectedFilters()})

    @viewport.find('select, input[type="checkbox"]').change(=>
      filtersChanged())
    @viewport.find('form').submit(=>
      filtersChanged()
      false) # don't actually submit the form
    @viewport.find('input[type="text"]').keypress((event) =>
      if event.which == 13 # apply filter when 'enter' pressed
        if event.target.lastFilteredOn != $(event.target).val()
          event.target.lastFilteredOn = $(event.target).val()
          filtersChanged()
        event.preventDefault())
    @viewport.find('input[type="text"]').change((event) =>
      if event.target.lastFilteredOn != $(event.target).val()
        event.target.lastFilteredOn = $(event.target).val()
        filtersChanged())

    that = this
    @viewport.find('select').change(->
      that.setSelectWidth($(this)))
    @refreshWidths()

  refreshWidths: ->
    that = this
    $.each(@viewport.find('select'), (i, val) -> that.setSelectWidth($(val)))

  clearFilters: ->
    @viewport.find('select, input[type="text"]').val('').each((i,element) ->
      element.lastFilteredOn = '')

  selectedFilters: ->
    filterData = @viewport.find('input,select,textarea').not('.ignore').serializeArray()
    filters = {}
    filters[field.name] = field.value for field in filterData when field.value != ""
    filters

  setSelectWidth: ($select) ->
    #The font argument matches the font-family, font-size, and font-style (default: normal) defined in the css
    $select.width($select.find('option:selected').text().width('1em system-ui')+25)

class ReportDownloader
  constructor: (@recordSource) ->

  okForDownload: (report) ->
    records = @recordSource.allRecords()
    if records.length > 3000
      alert("Sorry, you can't generate a report for more than 1000 records at once. (Right now, " + records.length + " are selected.)")
      false
    else if records.length == 0
      alert("No records are selected for inclusion in the report.")
      false
    else
      true

  download: (report, format, dialog) ->
    if @okForDownload(report)
      records = @recordSource.allRecords()
      ids = records.map((r) -> r.id)
      $.fileDownload('/office/download_report', {
        httpMethod: 'POST',
        data: {format: format, ids: ids.join(','), report: report},
        successCallback: ->
          dialog.modal('hide')
        failCallback: ->
          alert("Sorry, a server error occurred and the report could not be downloaded.")
          dialog.modal('hide')
      })

class ReportMenu
  constructor: (@dropdownMenu, @dialog, @downloader) ->
    @dropdownMenu.on('click', 'a', (event) =>
      reportName = $(event.target).attr('data-report-name')
      if @downloader.okForDownload(reportName)
        @dialog.open(reportName))

class ReportDialog
  constructor: (@viewport, @downloader) ->
    @viewport.modal({show: false})
    @viewport.find('a.download-xlsx').click(=>
      @downloader.download(@selectedReport, 'xlsx', @viewport))
    @viewport.find('a.download-csv').click(=>
      @downloader.download(@selectedReport, 'csv', @viewport))
    @viewport.find('a.download-pdf').click(=>
      @downloader.download(@selectedReport, 'pdf', @viewport))

  open: (reportName) ->
    @selectedReport = reportName
    @viewport.modal('show')


class Slideover
  constructor: (@slidingArea, @actor) ->
    @_in = false
    @slidingArea.find('.close').click(=> @actor.msg('saveAndClose', {from: @}))
    @slidingArea.find('.cancel').click(=> @actor.msg('close', {from: @}))

  slideIn: ->
    return if @_in
    @slidingArea.show(0).animate({left: '20%'})
    @_in = true
  slideOut: ->
    return unless @_in
    @slidingArea.animate({left: '100%'}).hide(0)
    @_in = false
  in: -> @_in

class FormChangeWatcher
  constructor: (@viewport, @actor) ->
    @clean = true
    @markClean()

    fireEvent = (input, value) =>
      if @clean && input.dirty
        @clean = false
        @actor.msg('dirty', {from: @, area: @viewport, input: input, was: input.orig, now: value})
      else if !@clean && !input.dirty
        # check all the other inputs, see if they are all clean
        unless @isAreaDirty(@viewport)
          @clean = true
          @actor.msg('clean', {from: @, area: @viewport})

    @viewport.on('change', 'select', ->
      unless $(this).hasClass('never-dirty')
        this.dirty = ($(this).val() != this.orig)
        fireEvent(this, $(this).val()))
    @viewport.on('change', "input[type='checkbox']", ->
      unless $(this).hasClass('never-dirty')
        this.dirty = (this.checked != this.orig)
        fireEvent(this, this.checked))
    @viewport.on('change', "input[type='number']", ->
      unless $(this).hasClass('never-dirty')
        this.dirty = (this.checked != this.orig)
        fireEvent(this, $(this).val()))
    @viewport.on('keyup', "input[type!='checkbox'],textarea", ->
      unless $(this).hasClass('never-dirty')
        this.dirty = ($(this).val() != this.orig)
        fireEvent(this, $(this).val()))

  markClean: ->
    @markAreaClean(@viewport)

  markAreaClean: (area) ->
    for input in area.find("input[type!='checkbox'],select,textarea")
      input.dirty = false
      input.orig  = $(input).val()
    for input in area.find("input[type='checkbox']")
      input.dirty = false
      input.orig  = input.checked
    unless @isAreaDirty(@viewport)
      if !@clean
        @actor.msg('clean', {from: @, area: @viewport})
      @clean = true

  revert: ->
    for input in @viewport.find("input,select,textarea")
      if input.dirty
        fillInput(input, input.orig)
        input.dirty = false
    if !@clean
      @actor.msg('clean', {from: @, area: @viewport})
    @clean = true

  recordOriginalValues: (area=@viewport) ->
    # some new inputs may have been added
    # but we don't want to mess with those which we were already watching before
    for input in area.find("input[type!='checkbox'],select,textarea")
      unless input.orig?
        input.orig  = $(input).val()
    for input in area.find("input[type='checkbox']")
      unless input.orig?
        input.orig  = input.checked

  isDirty: -> !@clean

  isAreaDirty: (area) ->
    $.makeArray(area.find('input,select,textarea')).some((x) -> x.dirty)

class RecordEditForm
  constructor: (@viewport, @actor, @formFiller) ->
    @watcher = new FormChangeWatcher(@viewport, @actor)
    delegate(@, @watcher, 'isDirty', 'revert', 'markClean')
    @_newRecord = true
    @_editingId = null

  isNewRecord: -> @_newRecord
  editingId:   -> @_editingId

  editRecord: (record) ->
    unless !@_newRecord && @_editingId == record.id
      @_newRecord = false
      @_editingId = record.id
      @formFiller(@viewport, record)
      @watcher.markClean()

  stopEditing: ->
    @_editingId = null

  refreshForm: (db, tableName) ->
    @formFiller(@viewport, db.findId(tableName, @_editingId))
    @watcher.markClean()

  newRecord: ->
    @_newRecord = true
    @_editingId = null
    @viewport.find('input[type="text"], textarea').val(null)
    @viewport.find('select option:selected').removeAttr('selected')
    @watcher.markClean()
    @formFiller(@viewport) if @formFiller

  saveRecord: (url, db, actor, fieldPrefix) ->
    @clearBadFields()

    url  += @_editingId if !@_newRecord
    data  = @viewport.find('input,select,textarea').serialize()
    ServerProxy.saveChanges(url, data, Actor(
      requestSuccess: (data) =>
        @watcher.markClean()
        actor.msg('saved', {from: @, result: data.result})
      requestError: (data) =>
        if data.bad_fields?
          @highlightBadFields(data.bad_fields.map((f) -> '#' + fieldPrefix + '_' + f))
        actor.msg('failed', {from: @, result: data.result})
      requestFailure: =>
        actor.msg('failed', {from: @})), db)

  highlightBadFields: (fields) ->
    fields.forEach((field) => @viewport.find(field).addClass('erroneous'))
  clearBadFields: ->
    @viewport.find('.erroneous').removeClass('erroneous')

  node: (query) -> @viewport.node(query)

# wraps and adds support for TinyMCE to RecordEditForm
# also adds 'clean'/'dirty' notification support for contents of TinyMCE instances
class TinyMceForm
  constructor: (@viewport, @actor, @formFiller) ->
    Actor(@)
    @form = new RecordEditForm(@viewport, @, @formFiller)
    delegate(@, @form, 'isNewRecord', 'editingId', 'stopEditing', 'highlightBadFields', 'clearBadFields', 'refreshForm', 'node')

    @editors = []
    $(window).load(=>
      editor_settings = {
        height: '300px',
        plugins: [
          'advlist autolink lists link charmap print preview hr anchor pagebreak',
          'searchreplace wordcount visualblocks visualchars fullscreen',
          'insertdatetime nonbreaking save table contextmenu directionality',
          'paste textcolor colorpicker textpattern imagetools toc'
        ],
        toolbar1: 'undo redo | bullist numlist | alignleft aligncenter alignright alignjustify | indent outdent | print preview',
        toolbar2: 'fontselect fontsizeselect | bold italic | forecolor backcolor | styleselect',
        fontsize_formats: '11pt 12pt 14pt 18pt 24pt 36pt',
        forced_root_blocks: false
      }
      @editors = $.makeArray(@viewport.find('.tinymce')).map((div) ->
        editor = new tinymce.Editor(div.id, editor_settings, tinymce.EditorManager)
        editor.model_prop = div.getAttribute('data-prop')
        editor.original_data = ''
        editor.render()
        editor)

      for editor in @editors
        do (editor) =>
          editor.on('change', =>
            if editor.isDirty()
              @dirty({from: @, area: @viewport})
            else
              @clean({from: @, area: @viewport}))
          editor.on('paste', =>
            editor.setDirty(true)
            @dirty({from: @, area: @viewport})))

  isDirty: ->
    @form.isDirty() || @editors.some((editor) -> editor.isDirty())

  editRecord: (record) ->
    @form.editRecord(record)
    @setData(editor, record[editor.model_prop]) for editor in @editors

  newRecord: ->
    @form.newRecord()
    @setData(editor, '') for editor in @editors

  saveRecord: (url, db, actor, fieldPrefix) ->
    @clearBadFields()

    url  += @editingId() if !@isNewRecord()
    data  = @viewport.find('input,select,textarea').serialize()
    for editor in @editors
      data += '&' + fieldPrefix + '[' + editor.model_prop + ']=' + encodeURIComponent(editor.getContent())

    ServerProxy.saveChanges(url, data, Actor(
      requestSuccess: (data) =>
        @markClean()
        actor.msg('saved', {from: @, result: data.result})
      requestError: (data) =>
        if data.bad_fields?
          @highlightBadFields(data.bad_fields.map((f) -> '#' + fieldPrefix + '_' + f))
        actor.msg('failed', {from: @, result: data.result})
      requestFailure: =>
        actor.msg('failed', {from: @})), db)

  markClean: ->
    @form.markClean()
    for editor in @editors
      editor.setDirty(false)

  revert: ->
    @form.revert()
    for editor in @editors
      setData(editor.originalData)

  dirty: (data) ->
    @actor.msg('dirty', data)

  clean: (data) ->
    if !@form.isDirty() && !@editors.some((editor) -> editor.isDirty())
      @actor.msg('clean', data)

  setData: (editor, data) ->
    data = data || ""
    editor.setContent(data)
    editor.originalData = data
    editor.setDirty(false)

class SlidingForm
  constructor: (@form, @viewport) ->
    @_active = false
    delegate(@, @form, 'saveRecord', 'isNewRecord', 'isDirty', 'revert', 'clearBadFields', 'markClean', 'editingId', 'refreshForm', 'node')
    @viewport ||= @form.viewport
    @slider = new Slideover(@viewport, @form.actor)
    delegate(@, @slider, 'slideIn', 'slideOut', 'in')
    @viewport.find('a.save').click(=> @form.actor.msg('saveAll', {from: @}))

  editRecord: (record) ->
    @_active = true
    @form.editRecord(record)
    @slider.slideIn()
    @form.actor.msg('postSlideIn', {from: @})
  newRecord: () ->
    @_active = true
    @form.newRecord()
    @slider.slideIn()
    @form.actor.msg('postSlideIn', {from: @})
  stopEditing: () ->
    @_active = false
    @slider.slideOut()
    @form.stopEditing()
  active: () -> @_active

class CommandBar
  constructor: (@viewport, @actor) ->
    for link in @viewport.find('.command-link')
      link = $(link)
      if command = link.attr('data-command')
        do (command, link) =>
          link.click(=> @actor.msg(command, {from: @}) unless link.hasClass('disabled'))

  disableCommand: (name) ->
    @viewport.find('.command-' + name).addClass('disabled')
  enableCommand: (name) ->
    @viewport.find('.command-' + name).removeClass('disabled')
  disableCommands: (names...) ->
    @disableCommand(name) for name in names
  enableCommands: (names...) ->
    @enableCommand(name) for name in names


class MapView
  # some parameters in this class have been carefully tweaked:
  # the cluster grid size of 22, max zoom of 15,
  # combined with forcing the markers onto a 0.001 degree lat/long grid
  # this allows us to see each individual marker at max zoom,
  # but clusters them as soon as you zoom out

  # sometimes when working locally with no Internet, the Google Maps API may not be available
  # in such cases, window.gmaps will not be defined, and we should just display a blank area
  constructor: (@viewport, @actor) ->
    @autozoom       = false
    @map = new gmaps?.Map(@viewport.find('.map')[0], {zoom: 8, minZoom: 5, maxZoom: 15, center: new gmaps.LatLng(53.83,-3.94)})

    # This function calculates the style, label, and mouseover 'tooltip' contents for a cluster
    #   of nearby map markers
    # We copy MapClusterer's built-in logic for determining the style and label,
    #   but do our own thing for the 'tooltip'
    cluster_properties = (markers, numStyles) ->
      count = markers.length.toString()
      post_areas = []
      for marker in markers
        subcode = subcodeFromRecord(marker.record)
        unless post_areas.indexOf(subcode) > -1
          post_areas.push(subcode)
      { text: count, index: Math.min(count.length, numStyles), title: post_areas.sort().join(', ') }
    @clusterer = @map? && new MarkerClusterer(@map, [], {gridSize: 40, calculator: cluster_properties, maxZoom: 14 })

  setAutozoom: (@autozoom) ->
    if @map? && @autozoom
      if @clusterer.markers_.length > 0
        @clusterer.fitMapToMarkers()
      else
        @showEntireUK()

  centerOnPoint: (lat, lng) ->
    @map?.setCenter(new gmaps.LatLng(lat,lng))

  showEntireUK: ->
    @map.setCenter(new gmaps.LatLng(53.83,-3.94))
    @map.setZoom(6)

  googleMap: -> @map

  draw: (records) ->
    return unless @map?
    bounds    = new gmaps.LatLngBounds
    markers   = []

    # we don't want multiple markers to land at the exact same spot
    # so we need to keep track of which spots are already occupied
    occupied  = {}
    offset    = 0.001 # 108 meters of latitude, less of longitude

    addMarker = (record) =>
      if coord = coordinatesForRecord(record)
        lat = parseFloat(coord[0].toFixed(3))
        lng = parseFloat(coord[1].toFixed(3))
        # offset points in a spiral pattern
        nextPoint = do ->
          step = 1; x = offset; y = 0; count = 0
          ->
            lat += x
            lng += y
            if (count += 1) == step
              count = 0; [x,y] = [y,-x]
              step += 1 if y == 0

        nextPoint() while occupied[lat.toFixed(3) + '_' + lng.toFixed(3)]

        coord = new gmaps.LatLng(lat, lng)
        bounds.extend(coord)
        marker = new gmaps.Marker({position: coord, title: record.name})
        marker.record = record
        gmapevt.addListener(marker, 'click', => @actor.msg('select', {from: @, record: record}))
        markers.push(marker)
        occupied[lat.toFixed(3) + '_' + lng.toFixed(3)] = true

    @clusterer.clearMarkers()
    addMarker(record) for record in records
    if markers.length > 0
      @clusterer.addMarkers(markers)
      if @autozoom
        @map.fitBounds(bounds)
    else if @autozoom
      @showEntireUK()


class QueryMap
  constructor: (@map, @db, @tableName) ->
    delegate(@, @map, 'setAutozoom', 'centerOnPoint', 'googleMap')
    @filters = {}
    @searchTerm = null
    @n_records = 0

  setFilters: (filters) ->
    @searchTerm = filters.search
    @filters = deepCopy(filters) # copy
    delete @filters.search

  draw: ->
    records = @db.queryAll(@tableName, @filters, null, null, @searchTerm)
    @n_records = records.length
    @map.draw(records)

  totalRecords: -> @n_records

class MultiAssigner
  constructor: (@viewport, @actor) ->
    @_choices  = [] # [[name, ID]]
    @_selected = [] # same
    @_qs1 = undefined
    @_qs2 = undefined

  choices: (@_choices) ->
  selected: (@_selected) ->
  initialize: ->
    #unfortunately, this newfangled multiselect doesn't have a way to remove options, so we reset the whole thing
    multiassigner = @
    @viewport.empty()
    @viewport.html("
      <div>
        <select class='assigner' multiple></select>
      </div>")
    #multiselect.js: http://loudev.com/
    @viewport.find('select.assigner').multiSelect({
      selectableHeader: "<input type='text' class='search-input' autocomplete='off'>",
      selectionHeader: "<input type='text' class='search-input' autocomplete='off'>",
      afterInit: (ms) ->
        that = @
        $selectableSearch = @$selectableUl.prev()
        $selectionSearch = @$selectionUl.prev()
        selectableSearchString = '#'+@$container.attr('id')+' .ms-elem-selectable:not(.ms-selected)'
        selectionSearchString ='#'+ @$container.attr('id')+' .ms-elem-selection.ms-selected'
        #Match only from the beginning of strings, case-insensitive
        options = {
          'prepareQuery': (val) ->
            new RegExp('^'+val, "i")
          'testQuery': (query, txt, _row) ->
            query.test(txt)
        }
        @qs1 = $selectableSearch.quicksearch(selectableSearchString, options)
        @qs2 = $selectionSearch.quicksearch(selectionSearchString, options)
        multiassigner._qs1 = @qs1
        @qs1.on('keydown', (e) ->
          #If user presses the down key in the search field, focus on the selector field
          if (e.which == 40)
            that.$selectableUl.focus();
            false)
        @qs2.on('keydown', (e) ->
          if (e.which == 40)
            that.$selectionUl.focus();
            false)
      afterSelect: (ids) ->
        @qs1.cache()
        @qs2.cache()
        original_selections = multiassigner._selected.map (option) -> option[1] || []
        for id in (ids.map (id_string) -> parseInt(id_string))
          if original_selections.indexOf(id) < 0
            multiassigner.viewport.find(".ms-elem-selection.ms-selected[ms-value='#{id}']").addClass('assigner-added')

      afterDeselect: (ids) ->
        @qs1.cache()
        @qs2.cache()
        original_selections =  multiassigner._selected.map (option) -> option[1] || []
        for id in (ids.map (id_string) -> parseInt(id_string))
          if original_selections.indexOf(id) >= 0
            multiassigner.viewport.find(".ms-elem-selectable[ms-value='#{id}']").addClass('assigner-removed')
    })

  draw: ->
    @initialize()
    for [name, value] in @_choices
      @viewport.find('select.assigner').multiSelect('addOption', {text: name, value: value})
    @_qs1.cache() # Search usually enabled on select. We enable manually for cases where they are no selected values
    values = []
    for [name, value] in @_selected
      values.push("#{value}")
    @viewport.find('select.assigner').multiSelect('select', values)

  getChanges: ->
    original_selection = @_selected.map (option) -> option[1] || []
    updated_selection = @viewport.find('select.assigner').val() || []
    updated_selection = updated_selection.map (id_string) -> parseInt(id_string)
    removed = []
    deleted = []
    removed = original_selection.filter((id)-> updated_selection.indexOf(id) < 0)
    added   = updated_selection.filter((id)-> original_selection.indexOf(id) < 0)
    {added: added, removed: removed}

ServerProxy =
  sendRequest: (url, data={}, actor=NullActor, db, method='GET', updateType, requestId, ajaxOptions) ->
    options = {url: url, method: method, data: data, dataType: 'json', cache: false}
    console.log(url)
    if ajaxOptions
      options = Object.assign({}, options, ajaxOptions)
    $.ajax(options)
      .done((result) =>
        if db && (result.tables? || result.deleted?)
          db.updateData(result, updateType)
        if result.status == 'ok'
          actor.msg('requestSuccess', {result: result, requestId: requestId}) if actor?
        else if result.status == 'error'
          actor.msg('requestError', {result: result, requestId: requestId}) if actor?)
      .fail((xhr, status) =>
        if status == 'parsererror'
          actor.msg('requestError', {result: {status: 'error', message: 'The server sent back a message which I couldn\'t understand. Please report this to the site developers.'}, requestId: requestId}) if actor?
        else if xhr.status == 0
          actor.msg('requestError', {result: {status: 'error', message: "I tried sending a message to the server, but it didn't go through. Is your computer connected to the Internet?"}, requestId: requestId}) if actor?
        else if xhr.status >= 500
          actor.msg('requestError', {result: {status: 'error', message: 'An error happened on the server. Please report this to the site developers.'}, requestId: requestId}) if actor?
        else
          actor.msg('requestError', {result: {status: 'error', message: 'An error happened. Please report this to the site developers.'}, requestId: requestId}) if actor?)

  saveChanges: (url, data, actor=NullActor, db, updateType, ajaxOptions={}) ->
    requestId = data.requestId ||= Math.random().toString(36)
    SavingChangesSpinner.startRequest(requestId)
    @sendRequest(url, data, new Tee(actor, SavingChangesSpinner, NotificationPopup), db, 'POST', updateType, requestId, ajaxOptions)

  saveFormData: (url, data, actor=NullActor, db, updateType) ->
    form_data = new FormData();
    for k,v of data
      form_data.append(k, v)
    @saveChanges(url, form_data, actor, db, updateType, {contentType: false, processData: false})

NotificationPopup = Actor(
  requestSuccess: (data) ->
    @showPopup('notice', data.result.message) if data.result?.message? && data.result.message != ''
  requestError: (data) ->
    @showPopup('error', data.result.message) if data.result?.message? && data.result.message != ''
  showPopup: (flag, text) ->
    @flashBacking ||= $('.flash-backing').click(-> $(this).fadeOut())
    @flashPopup   ||= $('.flash-backing .flash').on('click', 'input', (event) -> false)
    @flashPopup.empty()
    @flashPopup.append("<div class='" + flag + "-flag'></div>") if flag
    @flashPopup.append("<p>" + text.replace(/\n/g,"<br/>") + "</p>") if text
    @flashBacking.fadeIn())

ErrorOnlyPopup = Actor(
  requestSuccess: (data) -> EventsView::updateStatistics()
  requestError: (data) -> NotificationPopup.requestError(data))

SavingChangesSpinner = Actor(
  startRequest: (id) ->
    @activeRequests[id] = true
    $('.saving-changes').show(0)
  requestSuccess: (data) -> @requestFinished(data.requestId)
  requestError: (data) ->   @requestFinished(data.requestId)
  requestFailure: (data) -> @requestFinished(data.requestId)
  requestFinished: (requestId) ->
    delete @activeRequests[requestId]
    if Object.keys(@activeRequests).length == 0
      $('.saving-changes').fadeOut())

SavingChangesSpinner.activeRequests = {}

# export to global scope
window.ListView       = ListView
window.TableWidget    = TableWidget
window.MapView     = MapView
window.QueryMap       = QueryMap
window.DefaultListViewHandler = DefaultListViewHandler
window.CommandBar     = CommandBar
window.QueryTable     = QueryTable
window.TotalRowDisplay = TotalRowDisplay
window.PaginationControls = PaginationControls
window.TableWithPagination = TableWithPagination
window.RecordEditForm = RecordEditForm
window.SlidingForm    = SlidingForm
window.ServerProxy    = ServerProxy
window.FilterBar      = FilterBar
window.NotificationPopup = NotificationPopup
window.ErrorOnlyPopup    = ErrorOnlyPopup
window.ReportDownloader  = ReportDownloader
window.ReportDialog = ReportDialog
window.ReportMenu   = ReportMenu
window.EditableListView = EditableListView
window.EditableStaticListView = EditableStaticListView
window.MultiAssigner = MultiAssigner
window.TinyMceForm = TinyMceForm
window.SavingChangesSpinner = SavingChangesSpinner

{client} =  require '../connection'
modules = require './modules'

module.exports =
  gotoSymbol: ->
    editor = atom.workspace.getActiveTextEditor()
    mod = modules.current() # TODO: may not work in all cases
    edpath = editor.getPath() || 'untitled-' + editor.getBuffer().inkId
    [word, range] = @getWord editor
    # if we only find numbers or nothing, return prematurely
    if word.length == 0 || !isNaN(word) then return
    @ink.goto.goto client.rpc("methods", {word: word, mod: mod})

  # gets the word and its range in the `editor` which the last cursor is on
  getWord: (editor) ->
    cursor = editor.getLastCursor()
    # The following line is kinda iffy: The regex may or may not be well chosen
    # and it duplicates the efforts from atom-language-julia. It might be better
    # to select the current word via finding the smallest <span> containing the
    # cursor which also has `function` or `macro` as its class.
    range = cursor.getCurrentWordBufferRange({wordRegex: /[\u00A0-\uFFFF\w_!´]*\.?@?[\u00A0-\uFFFF\w_!´]+/})
    word = editor.getTextInBufferRange range
    [word, range]

shell =                 require 'shell'
{CompositeDisposable} = require 'atom'

module.exports =
  activate: (juno) ->

    if atom.config.get("julia-client.launchOnStartup")
      @withInk -> juno.connection.boot()

    requireClient    = (a, f) -> juno.connection.client.require a, f
    disrequireClient = (a, f) -> juno.connection.client.disrequire a, f
    boot = -> juno.connection.boot()
    listenOnly = -> juno.connection.listenOnly()
    connectTo = -> juno.connection.connectTo()
    disconnectFrom = -> juno.connection.disconnectFrom()

    cancelComplete = (e) ->
      atom.commands.dispatch(e.currentTarget, 'autocomplete-plus:cancel')

    @subs = new CompositeDisposable

    @subs.add atom.commands.add '.item-views > atom-text-editor',
      'julia-client:run-block': (event) =>
        cancelComplete event
        @withInk ->
          boot()
          juno.runtime.evaluation.eval()
      'julia-client:run-and-move': (event) =>
        @withInk ->
          boot()
          juno.runtime.evaluation.eval(move: true)
      'julia-client:run-file': (event) =>
        cancelComplete event
        @withInk ->
          boot()
          juno.runtime.evaluation.evalAll()
      'julia-client:toggle-documentation': =>
        @withInk ->
          boot()
          juno.runtime.evaluation.toggleMeta 'docs'
      'julia-client:toggle-methods': =>
        @withInk ->
          boot()
          juno.runtime.evaluation.toggleMeta 'methods'
      'julia-client:reset-workspace': =>
        requireClient 'reset the workspace', ->
          editor = atom.workspace.getActiveTextEditor()
          atom.commands.dispatch atom.views.getView(editor), 'inline-results:clear-all'
          juno.connection.client.rpc('clear-workspace')
      'julia:select-block': =>
        juno.misc.blocks.select()
      'julia-client:send-to-stdin': (e) =>
        requireClient ->
          ed = e.currentTarget.getModel()
          done = false
          for s in ed.getSelections()
            continue unless s.getText()
            done = true
            juno.connection.client.stdin s.getText()
          juno.connection.client.stdin ed.getText() unless done


    @subs.add atom.commands.add '.item-views > atom-text-editor[data-grammar="source julia"],
                                 ink-console.julia',
      'julia-client:set-working-module': -> juno.runtime.modules.chooseModule()

    @subs.add atom.commands.add 'atom-workspace',
      'julia-client:open-a-repl': -> juno.connection.terminal.repl()
      'julia-client:start-julia': -> disrequireClient 'boot Julia', -> boot()
      'julia-client:start-server': -> disrequireClient 'boot Julia', -> listenOnly()
      'julia-client:connect-to': -> connectTo()
      'julia-client:disconnect-from': -> disconnectFrom()
      'julia-client:kill-julia': => requireClient 'kill Julia', -> juno.connection.client.kill()
      'julia-client:interrupt-julia': => requireClient 'interrupt Julia', -> juno.connection.client.interrupt()
      'julia-client:open-console': => @withInk -> juno.runtime.console.open()
      "julia-client:clear-console": => juno.runtime.console.reset()
      'julia-client:open-plot-pane': => @withInk -> juno.runtime.plots.open()
      'julia-client:open-workspace': => @withInk -> juno.runtime.workspace.open()
      'julia-client:reset-loading-indicator': -> juno.connection.client.reset()
      'julia-client:settings': ->
        atom.workspace.open('atom://config/packages/julia-client')
      'julia-debug:step-to-next-line': => juno.runtime.debugger.nextline()
      'julia-debug:step-to-next-expression': => juno.runtime.debugger.stepexpr()
      'julia-debug:step-into-function': => juno.runtime.debugger.stepin()
      'julia-debug:finish-function': => juno.runtime.debugger.finish()

      'julia:open-startup-file': -> atom.workspace.open juno.misc.paths.home '.juliarc.jl'
      'julia:open-julia-home': -> shell.openItem juno.misc.paths.juliaHome()
      'julia:open-package-in-new-window': -> juno.misc.paths.openPackage()

      'julia-client:work-in-file-folder': ->
        requireClient 'change working folder', ->
          juno.runtime.evaluation.cdHere()
      'julia-client:work-in-project-folder': ->
        requireClient 'change working folder', ->
          juno.runtime.evaluation.cdProject()
      'julia-client:work-in-home-folder': ->
        requireClient 'change working folder', ->
          juno.runtime.evaluation.cdHome()
      'julia-client:select-working-folder': ->
        requireClient 'change working folder', ->
          juno.runtime.evaluation.cdSelect()

  deactivate: ->
    @subs.dispose()

  withInk: (f, err) ->
    if @ink?
      f()
    else if err
      atom.notifications.addError 'Please install the Ink package.',
        detail: 'Julia Client requires the Ink package to run.
                 You can install it from the settings view.'
        dismissable: true
    else
      setTimeout (=> @withInk f, true), 100

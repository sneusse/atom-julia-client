shell =                 require 'shell'
{CompositeDisposable} = require 'atom'

module.exports =
  activate: (juno) ->
    requireClient    = (f) -> juno.connection.client.require f
    disrequireClient = (f) -> juno.connection.client.disrequire f
    boot = -> juno.connection.boot()

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
        requireClient ->
          editor = atom.workspace.getActiveTextEditor()
          atom.commands.dispatch atom.views.getView(editor), 'inline-results:clear-all'
          juno.connection.client.rpc('clear-workspace')
      'julia:select-block': =>
        juno.misc.blocks.select()
      'julia-client:goto-symbol': =>
        @withInk ->
          boot()
          juno.runtime.symbols.gotoSymbol()

    @subs.add atom.commands.add '.item-views > atom-text-editor[data-grammar="source julia"],
                                 ink-console.julia',
      'julia-client:set-working-module': -> juno.runtime.modules.chooseModule()

    @subs.add atom.commands.add 'atom-workspace',
      'julia-client:open-a-repl': -> juno.connection.terminal.repl()
      'julia-client:start-julia': -> disrequireClient -> boot()
      'julia-client:open-console': => @withInk -> juno.runtime.console.open()
      "julia-client:clear-console": => juno.runtime.console.reset()
      'julia-client:open-plot-pane': => @withInk -> juno.runtime.plots.open()
      'julia-client:open-workspace': => @withInk -> juno.runtime.workspace.open()
      'julia-client:reset-loading-indicator': -> juno.connection.client.reset()
      'julia-client:settings': ->
        atom.workspace.open('atom://config/packages/julia-client')

      'julia:open-startup-file': -> atom.workspace.open juno.misc.paths.home '.juliarc.jl'
      'julia:open-julia-home': -> shell.openItem juno.misc.paths.juliaHome()
      'julia:open-package-in-new-window': -> juno.misc.paths.openPackage()

      'julia-client:work-in-file-folder': ->
        requireClient -> juno.runtime.evaluation.cdHere()
      'julia-client:work-in-project-folder': ->
        requireClient -> juno.runtime.evaluation.cdProject()
      'julia-client:work-in-home-folder': ->
        requireClient -> juno.runtime.evaluation.cdHome()
      'julia-client:select-working-folder': ->
        requireClient -> juno.runtime.evaluation.cdSelect()

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

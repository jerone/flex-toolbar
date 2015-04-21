rootDir = require('../index').getPackageRootDir()
shell = require 'shell'
path = require 'path'

module.exports =
  urlholder: ''

  toolbar: null

  config:
    toolbarConfigurationJsonPath:
      type: 'string'
      default: path.join rootDir, 'toolbar.json'
    showConfigButton:
      type: 'boolean'
      default: true
    reloadToolbarWhenEditJson:
      type: 'boolean'
      default: true

  activate: (state) ->

    if atom.packages.isPackageLoaded('toolbar')
      @initToolbar()
    else
      apd = require('atom-package-dependencies')
      apd.install =>
        @initToolbar()

    atom.commands.add 'atom-workspace',
      'flex-toolbar:edit-config-file': ->
        atom.workspace.open atom.config.get('flex-toolbar.toolbarConfigurationJsonPath')

    if atom.config.get('flex-toolbar.reloadToolbarWhenEditJson')
      watch = require 'node-watch'
      watch atom.config.get('flex-toolbar.toolbarConfigurationJsonPath'), =>
        @reloadToolbar()

  initToolbar: () ->
    atom.packages.activatePackage('toolbar')
      .then (pkg) =>
        @toolbar = pkg.mainModule

        try
          toolbarButtons = require atom.config.get('flex-toolbar.toolbarConfigurationJsonPath')
          delete require.cache[atom.config.get('flex-toolbar.toolbarConfigurationJsonPath')]
          @appendButtons(toolbarButtons)
        catch error
          console.log 'toolbar.json is not found.'

        if atom.config.get('flex-toolbar.showConfigButton')
          @toolbar.appendButton 'gear', 'flex-toolbar:edit-config-file', 'Edit toolbar', ''

  appendButtons: (toolbarButtons) ->
    if toolbarButtons?
      for btn in toolbarButtons
        switch btn.type
          when 'button'
            @toolbar.appendButton btn.icon, btn.callback, btn.tooltip, btn.iconset
          when 'spacer'
            @toolbar.appendSpacer()
          when 'url'
            @urlholder = btn.url
            @toolbar.appendButton btn.icon, =>
              shell.openExternal(@urlholder)
            , btn.tooltip, btn.iconset

  removeButtons: ->
    {$} = require 'space-pen'
    buttons = $(".tool-bar").children()
    buttons.remove()

  reloadToolbar: ->
    try
      toolbarButtons = require atom.config.get('flex-toolbar.toolbarConfigurationJsonPath')
      delete require.cache[atom.config.get('flex-toolbar.toolbarConfigurationJsonPath')]
      @removeButtons()
      @appendButtons toolbarButtons
      if atom.config.get('flex-toolbar.showConfigButton')
        @toolbar.appendButton 'gear', 'flex-toolbar:edit-config-file', 'Edit toolbar', ''
    catch error
      console.log 'json is not valid'

  deactivate: ->
    @removeButtons()

  serialize: ->

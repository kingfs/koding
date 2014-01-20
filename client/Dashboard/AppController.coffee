class DashboardAppController extends AppController

  handler = (group, callback)->
    KD.getSingleton('groupsController').ready ->
      KD.singleton('appManager').open 'Dashboard', callback

  KD.registerAppClass this,
    name                           : "Dashboard"
    routes                         :
      "/:name?/Dashboard"          : ({params : {section,name}})->
        handler name, (app)-> app.loadSection title : "Settings"
      "/:name?/Dashboard/:section" : ({params : {section,name}})->
        handler name, (app)-> app.loadSection title : decodeURIComponent section
    hiddenHandle : yes
    searchRoute : "/Dashboard?q=:text:"

  constructor: (options = {}, data) ->

    options.view = new DashboardAppView
      testPath   : "groups-dashboard"

    data or= KD.getSingleton('groupsController').getCurrentGroup()

    super options, data

    @tabData = [
        name         : 'Settings'
        viewOptions  :
          viewClass  : GroupGeneralSettingsView
          lazy       : yes
      ,
        name         : 'Members'
        viewOptions  :
          viewClass  : GroupsMemberPermissionsView
          lazy       : yes
          callback   : @bound 'membersViewAdded'
      ,
        name         : 'Invitations'
        viewOptions  :
          viewClass  : GroupsInvitationView
          lazy       : yes
      ,
        name         : 'Permissions'
        viewOptions  :
          viewClass  : GroupPermissionsView
          lazy       : yes
      ,
        name         : 'Membership policy'
        viewOptions  :
          viewClass  : GroupsMembershipPolicyDetailView
          lazy       : yes
          callback   : @bound 'policyViewAdded'
      # ,
      #   name         : 'Payment'
      #   viewOptions  :
      #     viewClass  : GroupPaymentSettingsView
      #     lazy       : yes
      #     callback   : @bound 'paymentViewAdded'
      ]

      if data.slug is "koding"
        @tabData.push
            name         : 'Products'
            kodingOnly   : yes
            viewOptions  :
              viewClass  : GroupProductSettingsView
              lazy       : yes
              callback   : @bound 'productViewAdded'
          ,
            name         : 'Blocked users'
            kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
            viewOptions  :
              viewClass  : GroupsBlockedUserView
              lazy       : yes
          ,
            name         : 'Badges'
            kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
            viewOptions  :
              viewClass  : BadgeDashboardView
              lazy       : yes
          ,
            name         : 'Widgets'
            kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
            viewOptions  :
              viewClass  : CustomViewsManager
              lazy       : yes
          ,
            name         : 'Administration'
            kodingOnly   : yes # this is only intended for koding group, we assume koding group is super-group
            viewOptions  :
              viewClass  : AdministrationView
              lazy       : yes

      # CURRENTLY DISABLED

      # ,
      #   name        : 'Vocabulary'
      #   viewOptions :
      #     viewClass : GroupsVocabulariesView
      #     lazy      : yes
      #     callback  : @vocabularyViewAdded
      # ,
      #   name        : 'Bundle'
      #   viewOptions :
      #     viewClass : GroupsBundleView
      #     lazy      : yes
      #     callback  : @bundleViewAdded


  fetchTabData: (callback) -> @utils.defer => callback @tabData

  membersViewAdded: (pane, view) ->
    group = view.getData()
    # pane.on 'PaneDidShow', ->
    #   view.refresh()  if pane.tabHandle.isDirty
    #   pane.tabHandle.markDirty no
    group.on 'MemberAdded', ->
      log 'MemberAdded'
      # {tabHandle} = pane
      # tabHandle.markDirty()

  loadSection: ({title}) ->
    @getView().nav.ready =>
      @getView().tabs.showPaneByName title

  policyViewAdded: (pane, view) ->

  paymentViewAdded: (pane, view) ->
    new GroupPaymentController { view }

  productViewAdded: (pane, view) ->
    new GroupProductsController { view }

  loadView: (mainView, firstRun = yes, loadFeed = no)->
    if firstRun
      @on "searchFilterChanged", (value) =>
        return if value is @_searchValue
        @_searchValue = Encoder.XSSEncode value
        @getOptions().view.search @_searchValue
        @loadView mainView, no, yes

  handleQuery:(query)->
    @getOptions().view.ready =>
      {q} = query
      if q
        @emit "searchFilterChanged", q
      else
        @emit "searchFilterChanged", ""
        super query


@gradecraft.factory 'Level', ['$http', 'Restangular', 'LevelBadge', ($http, Restangular, LevelBadge) ->
  class Level
    constructor: (criterion, attrs={}, $scope)->
      @$scope = $scope
      @id = attrs.id or null
      @criterion = criterion
      @badges = {}
      @availableBadges = angular.copy($scope.courseBadges)
      @selectedBadge = ""
      @id = if attrs.id then attrs.id else null

      @loadLevelBadges(attrs["level_badges"]) if attrs["level_badges"] #add badges if passed on init
      @criterion_id = criterion.id
      @name = attrs.name or ""
      @editingBadges = false
      @points = attrs.points || 0
      @fullCredit = attrs.full_credit or false
      @noCredit = attrs.no_credit or false
      @required = (attrs.full_credit || attrs.no_credit) || false
      @description = attrs.description or ""
      @resetChanges()
      @_initalizeExpectations(attrs.meets_expectations)

    isNew: ()->
      @id is null
    isSaved: ()->
      @id > 0
    change: ()->
      if @isSaved()
        @hasChanges = true

    resetChanges: ()->
      @hasChanges = false

    # first pass contstructor only
    _initalizeExpectations: (attr)->
      if attr == true
        @setAsCriterionExpectation()
      else
        @meetsExpectations = false

    # inidcated on the Criterion level that there is an expectation set
    setAsCriterionExpectation: ()->
      @meetsExpectations = true
      @criterion.meetsExpectationPoints = @points
      @criterion.meetsExpectationsSet = true

    # set all levels to false for meets expectations
    resetCriterionExpectation: ()->
      angular.forEach(@criterion.levels,(level,i)=>
        level.meetsExpectations = false
      )
      @criterion.meetExpectationPoints = 0
      @criterion.meetsExpectationsSet = false

    # this level meets or is above expectations
    pointsMeetExpectations: ()->
      return false if ! @criterion.meetsExpectationsSet
      @points >= @criterion.meetsExpectationPoints

    # boolean -- if expectation is set on a level for this criteria
    meetExpectationSet: ()->
      @criterion.meetsExpectationsSet == true

    # UI show status button
    showExpectationStatus: ()->
      return true if @meetsExpectations
      return true if ! @criterion.meetsExpectationsSet
      false

    toggleMeetsExpectations: ()->
      if @meetsExpectations == true
        @removeMeetsExpectations()
      else
        @putMeetsExpectations()

    # AJAX calls, should be in a service
    putMeetsExpectations: ()->
      $http.put("/api/levels/#{@id}", { level: { meets_expectations: true }})
        .success((data,status)=>
          @resetCriterionExpectation()
          @setAsCriterionExpectation()
          return true
        )
        .error((err)->
          console.log("Marking level as meets expectations failed")
          return false
        )
    removeMeetsExpectations: ()->
      $http.put("/api/levels/#{@id}", { level: { meets_expectations: false }})
        .success((data,status)=>
          @resetCriterionExpectation()
          return true
        )
        .error((err)->
          console.log("Removing level meets expectations failed")
          return false
        )

    params: ()->
      criterion_id: @criterion_id,
      name: @name,
      points: @points,
      description: @description
    criterionName: ()->
      alert @criterion.name
    removeFromCriterion: (index)->
      @criterion.levels.splice(index,1)

    ##rubric ctrl
    loadLevelBadge: (levelBadge)->
      courseBadge = @availableBadges[levelBadge.badge_id]
      loadedBadge = new LevelBadge(@, angular.copy(courseBadge))
      loadedBadge.id = levelBadge.id
      @badges[courseBadge.id] = loadedBadge # add level badge to level
      delete @availableBadges[courseBadge.id] # remove badge from available badges on level

    # Badges
    loadLevelBadges: (levelBadges)->
      angular.forEach(levelBadges, (levelBadge, index)=>
        if (@availableBadges[levelBadge.badge_id])
          @loadLevelBadge(levelBadge)
      )
    #rubric ctrl
    # Badges
    addBadge: (attrs={})->
      newBadge = new LevelBadge(@, attrs)
      @badges.splice(-1, 0, newBadge)
    addBadges: (levels)->
      angular.forEach(badges, (badge,index)=>
        @loadBadge(badge)
      )
    selectBadge: ()->
      newBadge = new LevelBadge(@, angular.copy(@selectedBadge), {create: true})

    deleteLevelBadge: (levelBadge)->
      $http.delete("/level_badges/#{levelBadge.id}").success(
        (data,status)=>
          @availableBadges[levelBadge.badge.id] = angular.copy(@$scope.courseBadges[levelBadge.badge.id])
          delete @badges[levelBadge.badge.id]
      ).error((err)->
        alert("delete failed!")
      )

    resetChanges: ()->
      @hasChanges = false
    editBadges: ()->
      angular.forEach(@$scope.criteria, (criterion,index)=>
        angular.forEach(criterion.levels, (level,index)=>
          level.editingBadges = false
        )
      )
      @editingBadges = true
    closeBadges: ()->
      @editingBadges = false
    params: ()->
      criterion_id: @criterion_id,
      name: @name,
      points: @points,
      description: @description
    create: ()->
      Restangular.all('levels').post(@params())
        .then(
          (response)=> #success
            @id = response.id
          (response)-> #error
        )
    modify: (form)->
      if form.$valid
        if @isNew()
          @create()
        else
          @update()

    update: ()->
      if @hasChanges
        Restangular.one('levels', @id).customPUT(@params())
          .then(
            ()-> #success
            ()-> #failure
          )
        @resetChanges()
    criterionName: ()->
      alert @criterion.name
    label: ()->
      if @fullCredit
        ["Full Credit Level", "Set As 'Meets Expectations'"]
      else if @meetsExpectations
        ["Meets Expectations","Remove 'Meets Expectations'"]
      else
        ["Set As 'Meets Expectations'", "Set As 'Meets Expectations'"]

    delete: (index)->
      if @isSaved()
        if confirm("Are you sure you want to delete this level?")
          $http.delete("/levels/#{@id}")
          .success((data,status)=>
            @removeFromCriterion(index)
            return true
          )
          .error((err)->
            alert("delete failed!")
            return false
          )
      else
        @removeFromCriterion(index)
    removeFromCriterion: (index)->
      @criterion.levels.splice(index,1)
]

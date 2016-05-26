@gradecraft.factory 'Criterion', ['$http', 'Restangular', 'Level', ($http, Restangular, Level) ->
  class Criterion
    constructor: (attrs={}, $scope)->
      @$scope = $scope
      @levels = []
      @badges = {}
      @id = if attrs.id then attrs.id else null
      @fullCreditLevel = null
      @meetsExpectationPoints = 0
      @meetsExpectationsSet = false
      @name = if attrs.name then attrs.name else ""
      @rubricId = if attrs.rubric_id then attrs.rubric_id else @$scope.rubricId
      if @id
        @max_points = if attrs.max_points then attrs.max_points else 0
      else
        @max_points = if attrs.max_points then attrs.max_points else null

      @description = if attrs.description then attrs.description else ""
      @hasChanges = false

      ## graderubric
      @selectedLevel = null

      # look for a rubric grade by criterion_id if there are rubric grades present
      if @$scope.criterionGrades
        @criterionGrade = @$scope.criterionGrades[@id]

      # if there are rubric grades, select the
      if @criterionGrade
        @criterionGradeLevelId = @criterionGrade.level_id
      else
        @criterionGradeLevelId = null

      if @criterionGrade
        @comments = @criterionGrade.comments
      else
        @comments = ""

      @addLevels(attrs["levels"]) if attrs["levels"] #add levels if passed on init

    addLevel: (attrs={})->
      newLevel = new Level(@, attrs, @$scope)
      @levels.push newLevel
      if @criterionGradeLevelId and @criterionGradeLevelId == newLevel.id
        @selectedLevel = newLevel

    # For adding new levels through UI, we want to insert them
    # before the Full Credit Level
    insertLevel: (attrs={})->
      newLevel = new Level(@, attrs, @$scope)
      @levels.splice(-1, -1, newLevel)

    addLevels: (levels)->
      angular.forEach(levels, (level,index)=>
        @addLevel(level)
      )
    resourceUrl: ()->
      "/criteria/#{@id}"
    order: ()->
      jQuery.inArray(this, @$scope.criteria)

    index: ()->
      @order()
    createCriterionGrade: ()->
      $http.post("/criterion_grades.json", @criterionGradeParams()).success().error()
    gradeWithLevel: (level)->
      if @isUsingLevel(level)
        @selectedLevel = null
      else
        @selectedLevel = level
    isUsingLevel: (level)->
      @selectedLevel == level
    criterionGradeParams: ()->
      {
        criterion_name: @name,
        criterion_description: @description,
        max_points: @max_points,
        order: @order,
        level_name: @selectedLevel.name,
        level_description: @selectedLevel.description,
        points: @selectedLevel.points,
        submission_id: submission_id,
        criterion_id: @id,
        level_id: @selectedLevel.id,
        comments: @comments
      }

    badgeIds: ()->
      # distill ids for all badges
      badgeIds = []
      angular.forEach(@badges, (badge, index)->
        badgeIds.push(badge.id)
      )
      badgeIds

    isNew: ()->
      @id is null
    isSaved: ()->
      @id != null
    change: ()->
      if @fullCreditLevel
        @updateFullCreditLevel()
      if @isSaved()
        @hasChanges = true
    updateFullCreditLevel: ()->
      @levels[0].points = @max_points
    resetChanges: ()->
      @hasChanges = false
    params: ()->
      {
        name: @name,
        max_points: @max_points,
        order: @order(),
        description: @description,
        rubric_id: @rubricId
      }
    destroy: ()->

    remove:(index)->
      @$scope.criteria.splice(index,1)
    create: ()->
      Restangular.all('criteria').post(@params())
        .then (response)=>
          criterion = response.existing_criterion
          @id = criterion.id
          @$scope.countSavedCriterion()
          @addLevels(criterion.levels)

    modify: (form)->
      if form.$valid
        if @isNew()
          @create()
        else
          @update()

    update: ()->
      if @hasChanges
        Restangular.one('criteria', @id).customPUT(@params())
          .then(
            ()-> , #success
            ()-> # failure
          )
        @resetChanges()

    delete: (index)->
      if @isSaved()
        if confirm("Are you sure you want to delete this criterion? Deleting this criterion will delete its levels as well.")
          $http.delete("/criteria/#{@id}").success(
            (data,status)=>
              @remove(index)
          )
          .error((err)->
            alert("delete failed!")
          )
      else
        @remove(index)
]

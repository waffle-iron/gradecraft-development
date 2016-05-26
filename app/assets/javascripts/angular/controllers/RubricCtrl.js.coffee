@gradecraft.controller 'RubricCtrl', ['$scope', 'Restangular', 'Criterion', 'CourseBadge', 'RubricService', '$http', ($scope, Restangular, Criterion, CourseBadge, RubricService, $http) ->
  Restangular.setRequestSuffix('.json')

  $scope.assignment = RubricService.assignment
  $scope.courseBadges = RubricService.badges
  $scope.criteria = RubricService.criteria

  $scope.savedCriterionCount = 0

  RubricService.getAssignment(window.location)
  RubricService.getBadges()
  RubricService.getCriteria($scope.assignment, $scope)

  $scope.init = (rubricId, pointTotal)->
    $scope.rubricId = rubricId
    $scope.pointTotal = parseInt(pointTotal)

  # distill key/value pairs for criterion ids and relative order
  $scope.pointsAssigned = ()->
    points = 0
    angular.forEach($scope.criteria, (criterion, index)->
      points += criterion.max_points if criterion.max_points
    )
    points or 0

  $scope.pointsDifference = ()->
    $scope.pointTotal - $scope.pointsAssigned()

  $scope.pointsRemaining = ()->
    pointsRemaining = $scope.pointsDifference()
    if pointsRemaining > 0 then pointsRemaining else 0

  # Methods for identifying point deficit/overage
  $scope.pointsMissing = ()->
    $scope.pointsDifference() > 0 and $scope.pointsAssigned() > 0

  $scope.pointsSatisfied = ()->
    $scope.pointsDifference() == 0 and $scope.pointsAssigned() > 0

  $scope.pointsOverage = ()->
    $scope.pointsDifference() < 0

  $scope.countSavedCriterion = () ->
    $scope.savedCriterionCount += 1

  $scope.newCriterion = ()->
    m = new Criterion(null, $scope)
    $scope.criteria.push m

  $scope.getNewCriterion = ()->
    $scope.newerCriterion = Restangular.one('criteria', 'new.json').getList().then ()->

  $scope.viewCriteria = ()->
    if $scope.criteria.length > 0
      $scope.displayCriteria = []
      angular.forEach($scope.criteria, (value, key)->
        $scope.displayCriteria.push(value.name)
      )
      $scope.displayCriteria

  $scope.existingCriteria = []

  # declare a sortableEle variable for the sortable function
  sortableEle = undefined

  # action when a sortable drag begins
  $scope.dragStart = (e, ui) ->
    ui.item.data "start", ui.item.index()
    return

  # action when a sortable drag completes
  $scope.dragEnd = (e, ui) ->
    start = ui.item.data("start")
    end = ui.item.index()
    $scope.criteria.splice end, 0, $scope.criteria.splice(start, 1)[0]
    $scope.$apply()
    $scope.updateCriterionOrder()
    return

  # send the criterion order to the server with ids
  $scope.updateCriterionOrder = ()->
    if $scope.savedCriterionCount > 0
      $http.put("/criteria/update_order", criterion_order: $scope.orderedCriteria()).success(
      )
      .error(
      )

  # distill key/value pairs for criterion ids and relative order
  $scope.orderedCriteria = ()->
    criteria = {}
    angular.forEach($scope.criteria, (value, index)->
      criteria[value.id] = {order: index} if value.id != null
    )
    criteria

  sortableEle = $("#criterion-box").sortable(
    start: $scope.dragStart
    update: $scope.dragEnd
  )
  return
]

Gradebook
=========

Assigns grades to [GradeCraft](../../README.md) students on assignments within courses.

## DESCRIPTION

A component of the GradeCraft application which contains the required objects and domain logic to allow staff to grade students.

### Dependencies

* [Classroom](../classroom)

## INSTALLATION

This component is installed via the [Gemfile](../../Gemfile) from the main GradeCraft application.

## RUNNING SPECS

1. `bundle install`
1. `bundle exec rake db:test:prepare`
1. `bundle exec rspec spec`

## CONTRIBUTING

1. Clone the repository `git clone https://github.com/UM-USElab/gradecraft-development`
1. Create a feature branch `git checkout -b my-awesome-feature`
1. Code!
1. Commit your changes (small commits please)
1. Push your new branch `git push origin my-awesome-feature`
1. Create a pull request `hub pull-request -b um-uselab:master -h um-uselab:my-awesome-feature`

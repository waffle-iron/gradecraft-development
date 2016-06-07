require_relative "condition_set/defer"

# Conditions are an optional layer on top of the Proctor class that adds
# flexibility for how and where various behaviors for any given Proctor
# subclass are defined. The problem that this attempts to solve is the
# definition of Proctor behaviors such as SomeProctor.showable? by simply
# constructing laundry lists of comparisons nested within if-else statements
# inside of a single method.
#
# Conditions separate these concerns out into requirements and overrides,
# both of which inherit from Proctor::Condition and are fundamentally wrappers
# for comparisons which are later called as a block to determine outcome.
#
# By standardizing this format we can use helpers like #satisfied_by?,
# requirements_passed?, and valid_overrides_present? to determine the status
# of a given set of conditions in various states.
#
# This module should be included in a Conditions class that corresponds to the
# Proctor that is using the set of conditions. For example a FooProctor class
# might use a FooConditions class to handle its logical concerns:
#
# class FooProctor < Proctor
#   def initialize(foo)
#     @foo = foo
#   end
#
#   def viewable_by?(user)
#     FooConditions.new(foo).for(:show).satisfied_by? user
#   end
# end
#
# class FooConditionSet
#   include Proctor::ConditionSet
#
#   def show_conditions
#     add_requirement :foo_equals_bar
#     add_override :bar_equals_bar
#   end
#
#   def foo_equals_bar
#     "foo" == "bar"
#   end
#
#   def bar_equals_bar
#     "bar" == "bar"
#   end
# end
#
module Proctor
  module ConditionSet
    # requirements and overrides will be arrays of Requirement and Override
    # objects respectively. user will be the user against which we're testing
    # the requirements and overrides.
    attr_accessor :requirements, :overrides, :user

    # by passing in the proctor here we gain access to the data fetched
    # in the Proctor, which will likely have some overlap to many or all sets
    # of conditions.
    attr_reader :proctor

    def initialize(proctor:)
      @proctor = proctor
      # set @requirements and @overrides to empty arrays
      reset_conditions
    end

    def self.included(base)
      # include additional class methods that can be used in the included class
      base.extend(Proctor::ConditionSet::Defer)
    end

    # This is used to establish the arrays for the requirements and overrides
    # against which the conditions are being checked.
    #
    def reset_conditions
      @requirements = []
      @overrides = []
    end

    # add a requirement for each method that has been listed in the
    # add_requirements call
    #
    def add_requirements(*requirement_names)
      requirement_names.each {|name| add_requirement name }
    end

    # add a override for each method that has been listed in the
    # add_overrides call
    #
    def add_overrides(*override_names)
      override_names.each {|name| add_override name }
    end

    # add a new requirement to the @requirements array on the given conditions
    # set. The Proc created by the block won't be called until the requirements
    # are checked later
    #
    def add_requirement(requirement_name)
      @requirements << Proctor::Requirement.new(name: requirement_name) do
        send(requirement_name)
      end
    end

    # add a new override to the @overrides array on the given conditions
    # set. The Proc created by the block won't be called until the overrides
    # are checked later
    #
    def add_override(override_name)
      @overrides << Proctor::Override.new(name: override_name) do
        send(override_name)
      end
    end

    # check whether all of the requirements in @requirements have passed
    def requirements_passed?
      requirements.all? {|requirement| requirement.passed? }
    end

    # check whether all of the overrides in @overrides have passed
    def valid_overrides_present?
      overrides.any? {|override| override.passed? }
    end
  end
end

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "classroom/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "classroom"
  s.version     = Classroom::VERSION
  s.authors     = ["GradeCraft"]
  s.email       = ["maintainers@gradecraft.com"]
  s.homepage    = "http://gradecraft.com"
  s.summary     = "Manages the GradeCraft faculty, students, and administative users."
  s.description = "The required objects and domain logic to allow users to belong to a classroom."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "pg"
  s.add_dependency "rails", "~> 4.2.3"

  s.add_development_dependency "rspec-rails", "~> 3.4.2"
end

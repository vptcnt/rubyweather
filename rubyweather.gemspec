require 'rake'

Gem::Specification.new do |s|
  s.name = %q{rubyweather}
  s.version = "1.1.0"
  s.date = %q{2006-07-28}
  s.summary = %q{Client library for accessing weather.com's xoap weather data.}
  s.email = %q{matt@roughest.net}
  s.homepage = %q{http://rubyforge.org/projects/rubyweather}
  s.rubyforge_project = %q{rubyweather}
  s.description = %q{RubyWeather is a Ruby library for fetching weather forecast data from weather.com. The library provides a nice Ruby-like abstraction layer for interacting with the service. Note that (free) registration with weather.com is required to access multi-day forecasts.}
  s.has_rdoc = true
  s.authors = ["Matt Zukowski"]
  s.files = FileList['*.rb', 'lib/**/*.rb', '[A-Z]*', 'test/*.rb', 'test/*.xml', 'example/**/*']
  s.test_files = Dir['test/*_test.rb']
  s.rdoc_options = ["--title", "RubyWeather #{s.version} RDocs", "--main", "README", "--line-numbers"]
  s.extra_rdoc_files = ["README", "LICENSE"]
end

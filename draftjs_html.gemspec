# frozen_string_literal: true

require_relative "lib/draftjs_html/version"

Gem::Specification.new do |spec|
  spec.name          = "draftjs_html"
  spec.version       = DraftjsHtml::VERSION
  spec.authors       = ["TJ Taylor"]
  spec.email         = ["dugancathal@gmail.com"]

  spec.summary       = "A tool for converting DraftJS JSON to HTML (and back again)"
  spec.description   = "A tool for converting DraftJS JSON to HTML (and back again)"
  spec.homepage      = "https://github.com/dugancathal/draftjs_html"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/tree/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.13"
  spec.add_development_dependency "rspec", "~> 3.0"
end

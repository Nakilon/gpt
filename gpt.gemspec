Gem::Specification.new do |spec|
  spec.name         = "gpt"
  spec.version      = "0.0.0"
  spec.summary      = "*GPT wapper"

  spec.author       = "Victor Maslov aka Nakilon"
  spec.email        = "nakilon@gmail.com"
  spec.license      = "MIT"
  spec.metadata     = {"source_code_uri" => "https://github.com/nakilon/gpt"}

  spec.add_dependency "nethttputils"
  spec.add_dependency "nakischema"

  spec.files        = %w{ LICENSE gpt.gemspec lib/gpt.rb }
end

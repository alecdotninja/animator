Gem::Specification.new do |s|
  s.name          = 'animator'
  s.version       = '0.0.1'
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'Inspired by the eligance of PaperTrail, Animator is a cleanly namespaced AcitveRecord plugin that hooks into the existing model lifecycle allowing you to to restore (`Animable#reanimate`), query (`Animable.inanimate`), and inspect (`Animable#divine`) destroyed objects--in most cases, including thier respective associations--without the tedium and ungliness of default scopes, monkey-patched methods, and complex callbacks.'
  s.description   = s.summary
  s.homepage      = 'https://github.com/AlecLarsen/animator'
  s.authors       = ['Alec Larsen']
  s.email         = 'aleclarsen42@gmail.com'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'activerecord', ['>= 3.0', '< 5.0']
  s.add_dependency 'activesupport', ['>= 3.0', '< 5.0']

  s.post_install_message = <<-eos

Animator will not work properly until the eraminhos table has been created. You can generate the proper migration by running `rails g animator:install`.

eos
end
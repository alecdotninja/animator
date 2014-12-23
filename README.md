Animator
========
Inspired by the elegance of [PaperTrail](https://github.com/airblade/paper_trail), Animator is a cleanly namespaced AcitveRecord plugin that hooks into the existing model life-cycle allowing you to to restore (`Animable#reanimate`), query (`Animable.inanimate`), and inspect (`Animable#divine`) destroyed objects--in most cases, including their respective associations--without the tedium and ugliness of default scopes, monkey-patched methods, and complex callbacks.

## Getting Started
Animator is opinionated software that protects all of all models right out of the box. Add it to your `Gemfile` and run the `bundle` command.
```ruby
gem 'animator'
```
Once the gem is installed, run the `animator:install` generator to create the necessary migration and default initializer.
```console
rails g animator:install
```
To selectively enable Animator, delete the initializer in `config/initializers/animator.rb` and include `Animator::Animable` on the desired models manually.
```ruby
class Task < ActiveRecord::Base
  include Animator::Animable
end
```
Finally, the database must be migrated to create the `eraminhos` table before Animator will work properly. 

_Note:_ In the very unlikely event that `eraminhos` needs to be preserved for use in the application, Animator may be configured to use an alternative table name by editing the migration and appending the following to the initializer.
```ruby
Animator::Eraminho.table_name = 'your_alternative_table_name_for_eraminhos'
```
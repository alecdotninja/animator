Animator
========
Inspired by the elegance of [PaperTrail](https://github.com/airblade/paper_trail), Animator is a cleanly namespaced ActiveRecord plugin that hooks into the existing model life-cycle allowing you to to restore (`Animable#reanimate`), query (`Animable.inanimate`), and inspect (`Animable#divine`) destroyed objects including associations without the tedium and ugliness of default scopes, monkey-patched methods, and complex callbacks.

## Getting Started
Animator is opinionated software that protects every model in the application right out of the box. 

Add it to your `Gemfile` and run the `bundle` command.
```ruby
gem 'animator'
```

Once the gem is installed, run the `animator:install` generator to create the necessary migration and default initializer.
```console
rails g animator:install
```

> **Note:** To selectively enable Animator, delete the initializer in `config/initializers/animator.rb` and include `Animator::Animable` on the desired models manually.

Finally, the database must be migrated to create the `eraminhos` table before Animator will work properly.
```console
rake db:migrate
```

> **Note:** In the very unlikely event that `eraminhos` needs to be preserved for use in the application, Animator may be configured to use an alternative table name by editing the migration and appending `Animator::Eraminho.table_name = 'alternative_table_name_for_eraminhos'` to the initializer.
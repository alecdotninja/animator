Animator
========
Inspired by the elegance of [PaperTrail](https://github.com/airblade/paper_trail), Animator is a cleanly namespaced ActiveRecord plugin that hooks into the existing model life-cycle allowing you to to restore (`Animable#reanimate`), query (`Animable.inanimate`), and inspect (`Animable#divine`) destroyed objects including associations without the tedium and ugliness of default scopes, monkey-patched methods, and complex callbacks.

## Getting Started
Out of the box, Animator is protects every model in the application. 

Add it to your `Gemfile` and run the `bundle` command.
```ruby
gem 'animator'
```

Once the gem is installed, run the `animator:install` generator to create the necessary migration and default initializer.
```console
rails g animator:install
```

> **Note:** To selectively enable Animator, delete the initializer in `config/initializers/animator.rb` and include `Animator::Animable` at the top of the desired models manually.

Finally, the database must be migrated to create the `eraminhos` table before Animator will work properly.
```console
rake db:migrate
```

> **Note:** In the very unlikely event that `eraminhos` needs to be preserved for use in the application, Animator may be configured to use an alternative table name by editing the migration and appending `Animator::Eraminho.table_name = 'alternative_table_name_for_eraminhos'` to the initializer.

## Usage

### Destroying

Animator works by registering an around_destroy callback, and therefore can only preserve data when the destroy callbacks are run. This means that calls to `ActiveRecord::Base#delete`, `ActiveRecord::Relation#delete_all`, and friends **cannot** be reversed. 

### Querying destroyed objects

`Animator::Animable` adds a scope called `inanimate` that can be used with existing scopes and `ActiveRecord::Relation`  methods to query and filter destroyed objects. Objects retrieved in this way will remain in the destroyed state (`destroyed?` is `true`) until they are reanimated.

### Reanimating

Animable objects (`animable?` is `true`) can be restored with a call to `reanimate` on the instance or `reanimate_all` on a relation. The reanimation callbacks will be triggered. By default, Animator restores relational objects by reversing the transaction in which the object was destroyed. An individual object may be reanimated by passing `transactional: false`. By default, Animator will reverse the entire transaction or leave the database unchanged. To leave objects in a transaction that cannot be reanimated destroyed, pass `force: true`. By default, at the end of reanimation just before the transaction is committed, Animator will run validations on all reanimated objects. To skip validations, pass `validate: false`.

### Inspecting destroyed objects

A block of code passed to `divine` on an animable object instance or relation will be executed within an automatically reversed transaction on the restored instance or relation. `divine` has the same defaults and accepts the same options as `reanimate` except validations will not be run by default.

### Troubleshooting reanimation issues

To be consistent with existing ActiveRecord behavior, plain Animator methods return a reference to the object on which they are called regardless of failure. This means that you must check `destroyed?` on an instance to know if `reanimate` was successful. The `!` versions of the methods will raise informative exceptions upon failure, and in some cases, provide troubleshooting tips.

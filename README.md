Animator
========
Inspired by the elegance of [PaperTrail](https://github.com/airblade/paper_trail), Animator is a cleanly namespaced ActiveRecord plugin that hooks into the existing model life-cycle allowing the restoration (`Animable#reanimate`) and querying (`Animable.inanimate`) of destroyed objects including associations without the tedium and ugliness of default scopes, monkey-patched methods, and complex callbacks.

## Getting Started
Add it to your `Gemfile` and run the `bundle` command.
```ruby
gem 'animator'
```

Once the gem is installed, run the `animator:install` generator to create the necessary migration and default initializer.
```console
rails g animator:install
```

> **Note:** Out of the box, Animator protects every model in the application. 
 To selectively enable Animator, delete the initializer in `config/initializers/animator.rb` and include `Animator::Animable` at the top of the desired models manually.

Finally, the database must be migrated to create the `eraminhos` table before Animator will work properly.
```console
rake db:migrate
```

> **Note:** In the very unlikely event that `eraminhos` needs to be preserved for use in the application, Animator may be configured to use an alternative table name by editing the migration and appending `Animator::Eraminho.table_name = 'alternative_table_name_for_eraminhos'` to the initializer.

## Usage

### Destroying

There's nothing special here. A simple call to `destroy` and friends will suffice. Animator infers dependent assocations by recording the transaction in which an object is destroyed.

> **Note:** Animator works by registering an after_destroy callback, and therefore can only preserve data when the destroy callbacks are run. This means that calls to methods like `delete` **cannot** be reversed.

### Querying

`Animator::Animable` adds a scope called `inanimate` that can be used with existing scopes and `ActiveRecord::Relation` methods to query and filter destroyed objects. Objects retrieved in this way will remain in the destroyed state (`destroyed?` is `true`) until they are reanimated.

### Reanimating

Animable objects (`animable?` is `true`) can be restored with a call to `reanimate` on the instance or `reanimate_all` on a relation. The reanimation callbacks will be triggered on the instance.

Animator restores relational objects by reversing the transaction in which the object was destroyed. An individual object may be reanimated by passing `false`. Animator will reverse the entire transaction or leave the database unchanged.

### Troubleshooting

To be consistent with existing ActiveRecord behavior, plain Animator methods return a reference to the object on which they are called regardless of failure. This means `destroyed?` on each instance must be checked to know if `reanimate` was successful. The `!` versions of the methods will raise informative exceptions upon failure, and in some cases, provide troubleshooting tips.

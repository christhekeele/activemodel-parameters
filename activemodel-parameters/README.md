ActiveModel::Parameters
=======================

Purpose
-------

`ActiveModel::Parameters` handles normalizing, transforming, and sanitizing controller parameter hashes into valid arguments for ActiveModel operations.

It provides a object-oriented approach over a hash-munging one to handling parameter preparation, leaving your controllers cleaner and safer.

Consider using it if:

- you need to normalize incoming data consistently.

  ex: converting between API and Rails conventions like `camelCase` vs `snake_case`

- you want to handle parameter permissions in a tenant fashion

  ex: permitting manual updates to timestamps if `current_user.admin?`

- you wish to mutate parameters consistently across controllers for the same models

  ex. nested `comments` should easily be transformed the same way without any extra work across all controllers

- you wish to mutate parameters differently across various controller actions for the same models

  ex. `users` should not be able to set their `registered_at` timestamps on `create`.

- you want to do any of the above in a clean, modular OOP fashion

  ex. you miss being able to do `user.attributes = @params` in anemic controllers, but want the secure defaults and fine-grained control of the alternatives.

AMP is designed to be familiar and easy to start with or move over to. It employs a class-based DSL inspired by `ActiveModel::Serializers`, so your incoming and outgoing objects can be understood with minimal cognitive load. It also supports an instance-level API very similar to `ActionController::StrongParameters`

AMP fully replaces `ActionController.wrap_parameters` and `ActionController::StrongParameters`. It is intended to read from those configuration settings as well as it's own initializer to make conversion easier, but this is not yet implemented.

Installation
------------

Execute the following commands to install AMP into your project,
or use the shell and package manager of your choice appropriately.

```sh
$ echo "gem 'activemodel-parameters'" >> Gemfile
$ bundle install
```

Usage
-----

### Generating Parameters

**Not implemented**

The easiest way to create new parameters is to generate a new resource, which
will generate parameters at the same time:

```
$ rails g resource post title:string body:string
```

This will generate parameters in `app/parameters/post_parameters.rb` for
your new model. You can also generate parameters for an existing model with
the parameters generator:

```
$ rails g parameters post
```

### Simple Parameters

Simple Parameters classes inherit from `ActiveModel::Parameters` and are constructed through the `attributes` method:

```ruby
class PostParameters < ActiveModel::Parameters
  attributes :title, :body
end
```

This allows us to transform arbitrary hashes into hashes ready to be passed into ActiveModel methods:

```ruby
PostParameters.new({ title: "Foo!", body: "Bar." }).to_hash
#=> { title: "Foo!", body: "Bar." }

PostParameters.new({ title: "Foo!", body: "Bar.", published: true }).to_hash
#=> ActiveModel::Parameters::Exceptions::UnpermittedParameters:
#=>  found unpermitted parameters: published
```

Specified attributes are always permitted. You can also require them:

```ruby
class PostParameters < ActiveModel::Parameters
  attributes :title, :body, required: true
end
PostParameters.new({ }).to_hash
#=> ActiveModel::Parameters::Exceptions::MissingParamters:
#=>  required parameters not found: title, body
```

This allows us to define common parameter behaviors across controllers. If a given controller has a specific requirement or custom permission, however, we can use instance-level customization:

```ruby
class PostParameters < ActiveModel::Parameters
  attribute :title, required: true
  attribute :body
end

params = PostParameters.new({ title: "Foobar" })

params.to_hash
#=> { title: "Foobar" }

params.require(:body)
params.to_hash
#=> ActiveModel::Parameters::Exceptions::MissingParamters:
#=>  required parameters for PostParameters not found: body

params[:body] = "Here you go!"
params.to_hash
#=> { title: "Foobar", body: "Here you go!" }

params[:published] = true
params.to_hash
#=> ActiveModel::Parameters::Exceptions::UnpermittedParameters:
#=>  found unpermitted parameters for PostParameters: published

params.permit(:published)
params.to_hash
#=> { title: "Foobar", body: "Here you go!", published: true }
```

Similar to `StrongParameters`, you can invoke `permit!` to allow all parameters. Unlike `StrongParameters`, `require` does not immediately trigger an error—requirements are only enforced when `to_hash` is invoked. If you want to perform an immediate requirement check, use `require!`.

Finally, while `to_hash` will convert your parameters object into something useful, it will not cascade to any nested parameters. Use `to_hash!` to do so. Consult [Constructing Parameters]() for more on nested parameters.

### Controller Integration

Your controllers will automatically search for a parameters class similar to the controller name: `PostsController` will search for a subclass of `ActiveModel::Parameters` called `PostParameters`. It will fall back to `ActiveModel::Parameters::Default` if that is not found.

You can manually set the parameters class per controller:

```ruby
class PostsController < ApplicationController
  parameter_class TrendingPostParameters
end
```

You can also set the `scope` used in the parameters:

```ruby
class PostsController < ApplicationController
  parameterization_scope :current_blog
end
```

This will use the current controller's `current_blog` method as the `scope` in your parameters classes, detailed below. It defaults to `:current_user`.

### Constructing Parameters

The Parameters DSL offers several features to make customizing your classes easier.

#### Attributes

The `attribute` directive permits attributes of that name to stay in the resultant hash:

```ruby
class PostParameters < ActiveModel::Parameters
  attribute :title
end
PostParameters.new({ title: "Foo!" }).to_hash
#=> { title: "Foo!" }
```

*Options:*

- required: Raises an error if attribute is not found.

  - default: false

  - accepts: `true`, `false`

  - example: `attribute :name, required: true`

- from: The hash key to look for this attribute.

  - default: attribute name

  - accepts: strings, symbols

  - example: `attribute :name, from: :full_name`

  - notes: This indicates that `{ full_name: "John Doe" }` will become `{ name: "John Doe" }` when `to_hash` is invoked, but { name: "John Doe" } will become `{}`.

    For less strict behavior see `aliases` below. This behavior may change in the future.

- aliases: Other places to look for this attribute.

  - default: `[]`

  - accepts: a lists of strings or symbols

  - example: `attribute :name, aliases: [:full_name, :legal_name]`

  - notes: This indicates that `{ full_name: "John Doe" }` will become `{ name: "John Doe" }` when `to_hash` is invoked.

    This behavior may be merged into `from` in the future.

The `attributes` directive behaves similarly to the `attribute` directive above, but accepts multiple attributes. It is recommended you do not use `:from` or `:alias` options with it.

#### Associations

Association directives allow nested hashes to be instantiated as other `Parameters` subclasses. The resultant hash can invoke `to_hash` on nested parameters individually, or call `to_hash!` on itself to recursively transform and permit associations. The nested hashes are prepared in `accepts_nested_attributes_for` style. Associations accept the same options as attributes, with some additional configuration.

Has One relations will operate on a single nested hash:

```ruby
class UserParameters < ActiveModel::Parameters
  has_one :profile
end
class ProfileParameters < ActiveModel::Parameters
  attributes :name, :email, :phone, required: true
end
user = UserParameters.new({ profile: { name: "John Doe", email: "john.doe@example.com" } })
user[:profile].to_hash
#=> ActiveModel::Parameters::Exceptions::MissingParamters:
#=>  required parameters for ProfileParameters not found: phone
user[:profile][:phone] = "0123456789"
user[:profile].to_hash!
#=> {
#=>   "name"=>"John Doe",
#=>   "email"=>"john.doe@example.com",
#=>   "phone"=>"0123456789"
#=> }
user.to_hash!
#=> {
#=>   "profile_attributes"=>{
#=>     "name"=>"John Doe",
#=>     "email"=>"john.doe@example.com",
#=>     "phone"=>"0123456789"
#=>   }
#=> }
```

Has Many relations will operate on a nested array of hashes:

```ruby
class UserParameters < ActiveModel::Parameters
  has_many :profiles
end
class ProfileParameters < ActiveModel::Parameters
  attributes :name, :email, :phone, required: true
end
user = UserParameters.new({ profiles: [
  { name: "John Doe", email: "john.doe@example.com", phone: "1234567890" },
  { name: "John Doe", email: "john.doe@example.com" }
]})
user.to_hash!
#=> ActiveModel::Parameters::Exceptions::MissingParamters:
#=>  required parameters for ProfileParameters not found: phone
user[:profiles].last[:phone] = "0987654321"
user.to_hash!
#=> {
#=>   "profiles_attributes"=> [
#=>     {
#=>       "name"=>"John Doe",
#=>       "email"=>"john.doe@example.com",
#=>       "phone"=>"1234567890"
#=>     }, {
#=>       "name"=>"John Doe",
#=>       "email"=>"john.doe@example.com",
#=>       "phone"=>"0987654321"
#=>     }
#=>   ]
#=> }
```

Both accept an additional option:

- parameter_class: AMP subclass to use for this association.

  - default: `"SingularRelationshipNameParameters"`

  - accepts: a class or string

  - example: `has_many :owners, parameter_class: :user`

  - notes: This indicates that `UserParameters` will be used to validate nested parameters.

Finally, Belongs To associations allow you to transform associations nested like `has_ones` into something ActiveRecord compatible:

```ruby
class CommentParameters < ActiveModel::Parameters
  belongs_to :user
end
CommentParameters.new({ user: { id: 123 } }).to_hash
#=> { user_id: 123 }
```

If no key is found, the attribute is omitted all together. It accepts additional options to control the re-mapping:

- foreign_key: What key to generate from this association

  - default: `"#{relationship_name}_id"`

  - accepts: a string

  - example: `belongs_to :company, primary_key: :organization_id`

  - notes: This indicates that `{ company: { id: 123, name: "asdf" } }` will become `{ organization_id: 123 }` when `to_hash` is invoked.

- key: What key to look for in this association

  - default: `"id"`

  - accepts: a string

  - example: `belongs_to :company, key: :uuid`

  - notes: This indicates that `{ company: { uuid: "239875202098735", name: "asdf" } }` will become `{ company_id: "239875202098735" }` when `to_hash` is invoked.

#### Transformations

AMP offers several options for transforming parameters:

#### Parameter Wrapping

#### Configuration





Contributing
------------

1. Acquaint yourself with the contents of CONTRIBUTING.md
2. Fork it at `github.com/christhekeele/active_model_parameters
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

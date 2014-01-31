ActiveModel::Parameters
=======================

Purpose
-------

`ActiveModel::Parameters` handles normalizing, transforming, and sanitizing attribute hashes into valid arguments for ActiveModel operations.

Parameter objects know how to transform arbitrary hashes into suitable parameters to an ActiveModel method. They collect the behavior of `StrongParameters`, `ActionController.wrap_parameters`, common transforms, and general hash-munging into simple, testable classes inspired by `ActiveModel::Serializers`.

It supports any object that responds to the `to_hash` or `to_json` method. Like AMS, it aims to **replace hash-driven development with object-oriented development**. It fully replaces and supports the `StrongParameters` API, and reads the configuration of those it replaces, allowing it to be seamlessly dropped into an existing Rails 4.0 application.

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem 'active_model_parameters'
```

And then execute:

```sh
$ bundle install
```

Usage
-----

### Generating Parameters

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

### Writing Parameters

Simple Parameters objects inherit from `ActiveModel::Parameters` and are constructed through the `attributes` method:

```ruby
class PostParameters < ActiveModel::Parameters
  attributes :title, :body
end
```

This allows us to transform arbitrary hashes into something easy to pass into `attributes=`:

```ruby
{ title: "" }

Contributing
------------

1. Acquaint yourself with the contents of CONTRIBUTING.md
2. Fork it at `github.com/christhekeele/active_model_parameters
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

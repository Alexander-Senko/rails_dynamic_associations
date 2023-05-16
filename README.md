# RailsDynamicAssociations

Define your model associations in the database without changing the schema or models.

## Features

* Creates associations for your models when application starts.
* Provides `Relation` & `Role` models.
* No configuration code needed.
* No code generated or inserted to your app (except migrations).
* Adds some useful methods to `ActiveRecord` objects to handle their relations.

## Installation

1. Add the gem to your `Gemfile` and `bundle` it.
2. Copy migrations to your app (`rake rails_dynamic_associations:install:migrations`).
3. Migrate the DB (`rake db:migrate`).

## Usage

Add configuration records to the DB:

``` ruby
	Relation.create({
		source_type: Person,
		target_type: Book,
	})
```

Or use a helper method:

``` ruby
	Relation.seed Person, Book
```

Now you have:

``` ruby
	person.books
	book.people
```

### Roles

You can create multiple role-based associations between two models.

``` ruby
	Relation.seed Person, Book, %w[
		author
		editor
	]
```

You will get:

``` ruby
	person.books
	person.authored_books
	person.edited_books

	book.people
	book.author_people
	book.editor_people
```

#### Special cases

In case you have set up relations with a `User` model you'll get a slightly different naming:

``` ruby
	Relation.seed User, Book, %w[
		author
		editor
	]
```

``` ruby
	book.users
	book.authors
	book.editors
```

The list of models to be handled this way can be set with `actor_model_names` configuration parameter.
It includes `User` by default.

###### TODO

* Describe self-referential associations.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

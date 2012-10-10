Suitcase
========

Ruby library that utilizes the EAN (Expedia.com) API for locating available hotels through their version 3 API. It also uses the Hotwire API to search for rental cars.

Installation
------------

Suitcase is a Ruby gem, meaning it can be installed via a simple `gem install suitcase`. It can also be added to a project's `Gemfile` with the following line: `gem 'suitcase'` (or `gem 'suitcase', git: "git://github.com/thoughtfusion/suitcase.git", branch: "develop"` for the latest updates).

Usage
-----

### Hotels

First, configure the library:

```ruby
Suitcase.configure do |config|
  config.hotel_api_key = "..." # set the Hotel API key from developer.ean.com
  config.hotel_cid = "..." # set the CID from developer.ean.com
  config.cache = Hash.new # set the caching mechanism (see below)
end
```

Full example:
```ruby
# Find Hotels in Boston
hotels = Suitcase::Hotel.find(location: "Boston, MA")
# Pick a specific hotel
hotel = hotels[1]
# Get the rooms for a specific date
rooms = hotel.rooms(arrivalDate: "7/1/2013", departureDate: "7/8/2013", rooms: [{ adults: 1, children_ages: [2, 3] }, { adults: 1, children_ages: [4] }])
# Find a payment option that is compatible with USD
payment_option = Suitcase::Hotel::PaymentOption.find(currency_code: "USD")
# Pick a specific room
room = rooms.first
# Set the bed type on each of the rooms to be ordered
room.rooms.each { |r| r[:bed_type] = room.bed_types.first }
# Reserve the room, with the reservation_hash described on 'User flow'
room.reserve!(reservation_hash)
```

#### Caching requests

You can setup a cache to store all API requests that do not contain secure information (i.e. anything but booking requests). A cache needs to be able store deeply nested Hashes and have a method called #[] to access them. An example of setting the cache is given above. Check the `examples/hash_adapter.rb` for a trivial example of the required methods. A Redis adapter is also in the examples directory.

#### Using the downloadable images

EAN provides a [downloadable image "database"](http://developer.ean.com/database_catalogs/relational/Image_Data) that doesn't require using the image URLs fetched by the API.For example usage of this database, check out `examples/hotel_image_db.rb`.

### Car rentals

Add the required configuration options:

```ruby
# Or add to your existing configure block
Suitcase.configure do |config|
  config.hotwire_api_key = "..." # set the Hotwire API key
  config.hotwire_linkshare_id = "..." # optionally set the Hotwire linkshare ID
end
```

Example usage:

```ruby
# Find all rental cars from the specified dates/times at LAX
rentals = Suitcase::CarRental.find(destination: "LAX", start_date: "7/14/2012", end_date: "7/21/2012", pickup_time: "6:30", dropoff_time: "11:30")
# => [#<Suitcase::CarRental ...>, ...]
```

Caching is not recommended for car rentals, because they all change so quickly.

Contributing
------------

### Running the tests

To set up for the tests, you need to edit the file `test/keys.rb` with the proper information. Currently, testing reservations is unsupported. You can run the tests with the default rake task by running `rake` from the command line.

### Pull requests/issues

Please submit any useful pull requests through GitHub, preferably to the `develop` branch in the repo. If you find any bugs, please report them with the issue tracker! Thanks.

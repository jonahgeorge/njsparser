# NJSParser

A powerful **parser** and **explorer** for any website built with [NextJS](https://nextjs.org).
- Parses flight data (from the **`self.__next_f.push`** scripts).
- Parses next data from **`__NEXT_DATA__`** script.
- Parses **build manifests**.
- Searches for **build id**.
- Many other things ...

```ruby
gem 'njsparser'
```

### Parsing `__next_f`.

The data you find in `__next_f` is called flight data, and contains data under react format. You can parse it easily with `njsparser` the way it follows.

*We will build a parser for the flight data example*

1. In the website you want to parse, make sure you see the `self.__next_f.push` in the beginning of script contained the data you search for.
2. Then you can do this simple script, to parse, then dump the flight data of your website, and see what objects you are searching for:

   ```ruby
   require 'njsparser'
   require 'net/http'
   require 'json'

   # Here I get my page's html
   uri = URI('https://mediux.pro/user/r3draid3r04')
   response = Net::HTTP.get_response(uri)
   
   # Then I parse it with njsparser
   fd = Njsparser::BeautifulFD(response.body)
   
   # Then I will write to json the content of the flight data
   File.open("fd.json", "w") do |file|
     # I use the njsparser.default function to support the dump of the flight data objects.
     file.write(JSON.pretty_generate(fd, &Njsparser.method(:default)))
   end
   ```

3. In your dumped flight data, search for the same string.
4. Then go to the closed `"value"` root to your found string, and look at the value of `"cls"`. Here it is `"Data"`.
5. Now that you know the `"cls"` (class) of object your data is contained in, you can search for it in your `BeautifulFD` object:

   ```ruby
   require 'njsparser'
   require 'net/http'

   # Here I get my page's html
   uri = URI('https://mediux.pro/user/r3draid3r04')
   response = Net::HTTP.get_response(uri)
   
   # Then I parse it with njsparser
   fd = Njsparser::BeautifulFD(response.body)
   
   # Then I iterate over the different classes `Data` in my flight data.
   data = nil
   fd.find_iter(class_filters: [Njsparser::T::Data]) do |item|
     # Then I make sure that the content of my data is not None, and
     # check if the key `"user"` is in the data's content. If it is,
     # then i break the loop of searching.
     if item.content && item.content.key?("user")
       data = item
       break
     end
   end

   raise "Did not find any dict :'(" unless data

   # Now i have the data of my user
   user = data.content["user"]
   # And I can print the string i was searching for before
   puts user["tagline"]
   ```

More informations:
- If your object is inside another object (e.g. `"Data"` in a `"DataParent"`, or in a `"DataContainer"`), the `.find_iter` will also find it recursively (except if you set `recursive: false`).
- Make sure you use the correct flight data classes attributes when fetching their data. The class `"Data"` has a `.content` attribute. If you use `.value`, you will end up with the raw value and will have to parse it yourself. If you work with a `"DataParent"` object, instead of using `.value` (that will give you `["$", "$L16", nil, {"children": ["$", "$L17", nil, {"profile": {}}]}]`), use `.children` (that will give you a `"Data"` object with a `.content` of `{"profile": {}}`). Check for the [type file](lib/njsparser/parser/types.rb) to see what classes you're interested in, and their attributes.
- You can also use `.find` on `BeautifulFD` to return the only first occurence of your query, or nil if not found.

### Parsing `<script id='__NEXT_DATA__'>`

Just do:

```ruby
require 'njsparser'

html_text = ...
data = Njsparser.get_next_data(html_text)
```

If the page contains any script `<script id='__NEXT_DATA__'>`, it will return the json loaded data, otherwise will return `nil`.


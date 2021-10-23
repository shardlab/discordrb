# frozen_string_literal: true

module HelperMethods
  def load_data_file(*name)
    JSON.parse(File.read("#{File.dirname(__FILE__)}/json_examples/#{name.join('/')}.json"))
  end

  # Creates a helper method that gives access to a particular fixture's data.
  # @example Load the JSON file at "spec/data/folder/filename.json" as a "data_name" helper method
  #   fixture :data_name, [:folder, :filename]
  # @param name [Symbol] The name the helper method should have
  # @param path [Array<Symbol>] The path to the data file to load, originating from "spec/data"
  def fixture(name, path)
    let name do
      load_data_file(*path)
    end
  end

  # Creates a helper method that gives access to a specific property on a particular fixture.
  # @example Add a helper method called "property_value" for `data_name['properties'][0]['value'].to_i`
  #   fixture_property :property_value, :data_name, ['properties', 0, 'value'], :to_i
  # @param name [Symbol] The name the helper method should have
  # @param fixture [Symbol] The name of the fixture the property is on
  # @param trace [Array] The objects to consecutively pass to the #[] method when accessing the data.
  # @param filter [Symbol, nil] An optional method to call on the result, in case some conversion is necessary.
  def fixture_property(name, fixture, trace, filter = nil)
    let name do
      data = send(fixture)

      trace.each do |e|
        data = data[e]
      end

      if filter
        data.send(filter)
      else
        data
      end
    end
  end
end

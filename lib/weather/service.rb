#
# Author::    Matt Zukowski  (http://blog.roughest.net)
# Copyright:: Copyright (c) 2006 Urbacon Ltd.
# License::   GNU Lesser General Public License v2.1 (LGPL 2.1)
#

require 'net/http'
require 'rexml/document'

require File.dirname(File.expand_path(__FILE__)) + '/forecast'

module Weather

  # Interface for interacting with the weather.com service.
  class Service
    attr_writer :partner_id, :license_key, :imperial
    attr_reader :partner_id, :license_key, :imperial
    
    # Returns the forecast data fetched from the weather.com xoap service for the given location and number of days.
    def fetch_forecast(location_id, days = 5)
      
      days = 5 if days.nil? or days.empty?
      
      # try to pull the partner_id and license_key from the environment if not already set
      partner_id = ENV['WEATHER_COM_PARTNER_ID'] unless partner_id
      license_key = ENV['WEATHER_COM_LICENSE_KEY'] unless license_key
      
      if imperial or (ENV.has_key? 'USE_IMPERIAL_UNITS' and ENV['USE_IMPERIAL_UNITS'])
        imperial = true
      else
        imperial = false
      end
      
      # NOTE: Strangely enough, weather.com doesn't seem to be enforcing the partner_id/license_key stuff. You can specify blank values for both
      #       and the service will return the data just fine (actually, it will accept any value as valid). I'm commenting out these checks
      #       for now, but we may need to re-enable these once weather.com figures out what's going on.
      #if not partner_id
      #  puts "WARNING: No partner ID has been set. Please obtain a partner ID from weather.com before attempting to fetch a forecast, otherwise the data you requested may not be available."
      #end
      #
      #if not license_key
      #  puts "WARNING: No license key has been set. Please obtain a license key from weather.com before attempting to fetch a forecast, otherwise the data you requested may not be available"
      #end
      
      # default to metric (degrees fahrenheit are just silly :)
      unit = imperial ? "s" : "m"
      puts "#{location_id} #{partner_id} #{license_key} DAYS: #{days.inspect}"
      host = "xoap.weather.com"
      url = "/weather/local/#{location_id}?cc=*&dayf=#{days}&prod=xoap&par=#{partner_id}&key=#{license_key}&unit=#{unit}"
      
      # puts "Using url: "+url
      
      if cache? and xml = cache.get("#{location_id}:#{days}")
      else
        xml = Net::HTTP.get(host, url)
        
        if cache?
          # TODO: most of the processing time seems to be in parsing xml text to REXML::Document... 
          #        maybe we should try caching some other serialized form? YAML?
          doc = REXML::Document.new(xml)
          doc.root.attributes['cached_on'] = Time.now 
          cache.set("#{location_id}:#{days}", doc.to_s, cache_expiry)
        end
      end
      puts xml
      doc = REXML::Document.new(xml)

      Forecast::Forecast.new(doc)
    end
    
    # Returns the forecast data loaded from a file. This is useful for testing.
    def load_forecast(filename)
      file = File.new(filename)
      doc = REXML::Document.new(file)
      
      Forecast::Forecast.new(doc)
    end
    
    # Returns a hash containing location_code => location_name key-value pairs for the given location search string.
    # In other words, you can use this to find a location code based on a city name, ZIP code, etc.
    def find_location(search_string)
      host = "xoap.weather.com"
      # FIXME: need to do url encoding of the search string!
      url = "/weather/search/search?where=#{search_string}"
      
      xml = Net::HTTP.get(host, url);
      doc = REXML::Document.new(xml)
      
      locations = {}
      
      REXML::XPath.match(doc.root, "//loc").each do |loc|
        locations[loc.attributes['id']] = loc.text
      end
      
      return locations
    end
    
    
    @cache = false
    
    # Turns on weather forecast caching.
    # See Weather::Service::Cache
    def enable_cache(enable = true)
      if enable
        extend Cache
        @cache = true
      else
        @cache = false
      end
    end
    
    # True if caching is enabled and at least one memcached server is alive, false otherwise.
    def cache?
      @cache and cache.active? and not cache.servers.dup.delete_if{|s| !s.alive?}.empty?
    end
    
    # Turns off weather forecast caching.
    # See Weather::Service::Cache
    def disable_cache
      enable_cache false
    end
    
    # Memcache functionality for Weather::Service.
    # This is automatically mixed in when you call Weather::Service#enable_cache
    module Cache
  
      # The MemCache client instance currently being used.
      # To set the memcache servers, use:
      # 
      #   service.cache.servers = ["127.0.0.1:11211"]
      def cache
        @memcache ||= MemCache.new(:namespace => 'RubyWeather')
      end
      
      # Sets how long forecast data should be cached (in seconds).
      def cache_expiry=(seconds)
        @cache_expiry = seconds
      end
      # The current cache_expiry setting, in seconds.
      def cache_expiry
        @cache_expiry || 60 * 10
      end
      
      private
        def self.extend_object(o)
          begin
            require 'memcache'
          rescue LoadError
            require 'rubygems'
            # We use Ruby-MemCache because it works. Despite my best efforts, I 
            # couldn't get the memcache-client implementation working properly.
            require_gem 'Ruby-MemCache'
            require 'memcache'
          end
          super
        end
    end
  end
end
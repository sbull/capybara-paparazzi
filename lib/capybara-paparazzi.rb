require 'capybara'

require 'capybara/paparazzi/version'
require 'capybara/paparazzi/shooter'
require 'capybara/paparazzi/driver'
require 'capybara/paparazzi/element'
require 'capybara/paparazzi/session'

module Capybara::Paparazzi

  module ClassMethods

    def config(&block)
      Capybara::Paparazzi::Shooter.config(&block)
    end

    def follow(*driver_names)
      driver_names.each do |name|
        used_drivers[name] = true
      end
    end

    def used_drivers
      @used_drivers ||= {}
    end

    def take_snapshots(driver, event_details=nil)
      Capybara::Paparazzi::Shooter.take_snapshots(driver, event_details)
    end

  end # ClassMethods

  extend ClassMethods
end

class Capybara::Node::Element
  include Capybara::Paparazzi::Element
end

class Capybara::Session
  include Capybara::Paparazzi::Session
end

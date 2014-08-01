require 'capybara'

require 'capybara/paparazzi/version'
require 'capybara/paparazzi/dsl'
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

    def take_snapshots(driver, event, args)
      Capybara::Paparazzi::Shooter.take_snapshots(driver, { event: event, args: args })
    end

    def take_snapshots_if_following(driver, event, args)
      if driver.is_a?(Capybara::Paparazzi::Driver)
        take_snapshots(driver, event, args)
      end
    end

    def without_snapshots(driver, &block)
      Capybara::Paparazzi::Shooter.without_snapshots(driver) do
        yield
      end
    end

    def turn_off(driver)
      Capybara::Paparazzi::Shooter.turn_off(driver)
    end

    def turn_on(driver)
      Capybara::Paparazzi::Shooter.turn_on(driver)
    end

  end # ClassMethods

  extend ClassMethods
end

module Capybara::DSL
  include Capybara::Paparazzi::DSL
end

class Capybara::Node::Element
  include Capybara::Paparazzi::Element
end

class Capybara::Session
  include Capybara::Paparazzi::Session
end

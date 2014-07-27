module Capybara::Paparazzi::Session

  def driver_with_paparazzi(*args)
    driver = driver_without_paparazzi(*args)
    if Capybara::Paparazzi.used_drivers[mode] && !driver.is_a?(Capybara::Paparazzi::Driver)
      driver.extend(Capybara::Paparazzi::Driver)
    end
    driver
  end

  def self.included(mod)
    mod.send(:alias_method, :driver_without_paparazzi, :driver)
    mod.send(:alias_method, :driver, :driver_with_paparazzi)
  end

end
